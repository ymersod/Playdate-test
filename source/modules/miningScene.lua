local pd <const> = playdate
local gfx <const> = pd.graphics
local feedback = import("modules/rockFeedback")
local scene = {}
local background = gfx.image.new("assets/textures/ui/backgroundMineshaftBlackBorderWhiteOutline")
local idleDrill = gfx.image.new("assets/textures/ui/drill"):scaledImage(0.5)
local hotDrill = gfx.image.new("assets/textures/ui/drill_blank"):scaledImage(0.5)
local drillFrames = {
	gfx.image.new("assets/textures/ui/drlil_animation1"),
	gfx.image.new("assets/textures/ui/drill_animation2"),
	gfx.image.new("assets/textures/ui/drill_animation3"),
	gfx.image.new("assets/textures/ui/drill_animation4"),
}
for index, image in ipairs(drillFrames) do
	drillFrames[index] = image:scaledImage(0.5)
end
local function RockMask(image)
	if image:sample(0, 0) ~= gfx.kColorWhite then return end
	local width, height = image:getSize()
	local mask = gfx.image.new(width, height, gfx.kColorWhite)
	local pending, cursor = { 0 }, 1
	gfx.pushContext(mask)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawPixel(0, 0)
	local function Visit(x, y)
		if x < 0 or x >= width or y < 0 or y >= height then return end
		if mask:sample(x, y) == gfx.kColorWhite and image:sample(x, y) == gfx.kColorWhite then
			gfx.drawPixel(x, y)
			table.insert(pending, y * width + x)
		end
	end
	while cursor <= #pending do
		local pixel = pending[cursor]
		local x, y = pixel % width, math.floor(pixel / width)
		Visit(x - 1, y)
		Visit(x + 1, y)
		Visit(x, y - 1)
		Visit(x, y + 1)
		cursor += 1
	end
	gfx.popContext()
	return mask
end

local rockFrames = {}
for index = 1, 3 do
	local path = "assets/textures/stone" .. index .. "/stone" .. index
	local frames = {
		gfx.image.new(path .. "_default"),
		gfx.image.new(path .. "_slightly_cracked"),
		gfx.image.new(path .. "_cracked"),
	}
	if index == 1 then table.insert(frames, gfx.image.new(path .. "_broken")) end
	local mask = RockMask(frames[1])
	if mask then
		for _, frame in ipairs(frames) do frame:setMaskImage(mask) end
	end
	rockFrames["rock" .. index] = frames
end
local oreImages = {}
for _, name in ipairs({ "Coal", "Topaz", "Diamond", "Emerald", "Ruby" }) do
	oreImages[name] = gfx.image.new("assets/textures/ores/" .. string.lower(name))
end

local small = gfx.font.new("fonts/Roobert-10-Bold")
local body = gfx.font.new("fonts/Roobert-11-Medium")
local heading = gfx.font.new("fonts/Roobert-20-Medium")

local pieces = {}
local splitRock = gfx.image.new("assets/textures/stone1/stone1_broken_splitterpieces")
for _, rect in ipairs({ { 2, 72, 27, 32 }, { 107, 51, 20, 21 }, { 95, 93, 22, 21 } }) do
	local image = gfx.image.new(rect[3], rect[4])
	gfx.pushContext(image)
	splitRock:draw(-rect[1], -rect[2])
	gfx.popContext()
	table.insert(pieces, image)
end

local particles = {}
local drops = {}
local drillY, drillVelocity = 176, 0
local kick, kickVelocity = 0, 0
local activity, phase, spin = 0, 0, 0
local visibleMoney = 0
local collectedAt, collectedValue = -10000, 0
local collectedName = ""
local pendingValue, pendingName = 0, ""
local breakAt = -10000
local finds = {}
local impact = 0

local function Text(text, x, y, font, white)
	gfx.setFont(font)
	gfx.setImageDrawMode(white and gfx.kDrawModeFillWhite or gfx.kDrawModeCopy)
	gfx.drawText(text, math.floor(x), math.floor(y))
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

local function Particle(x, y, vx, vy, life, image)
	if #particles >= 28 then
		table.remove(particles, 1)
	end
	table.insert(particles, { x = x, y = y, vx = vx, vy = vy, life = life, age = 0, image = image })
end

function scene.Reset(money)
	feedback.Reset()
	particles = {}
	drops = {}
	drillY, drillVelocity = 176, 0
	kick, kickVelocity = 0, 0
	activity, phase, spin = 0, 0, 0
	visibleMoney = money
	collectedAt, breakAt = -10000, -10000
	collectedValue = 0
	pendingValue, pendingName = 0, ""
	finds = {}
end

function scene.Hit(now, rock)
	feedback.Hit(now)
	breakAt = -10000
	kick, kickVelocity = -3, 0
	impact += 1
	local x = rock.sprite.x + 64
	local y = rock.sprite.y + 91
	for index = 1, 3 do
		local direction = (index + impact) % 2 == 0 and -1 or 1
		Particle(x + direction * 8, y, direction * (24 + index * 13), -24 - index * 12, 0.28 + index * 0.04)
	end
end

function scene.Break(now, rock, reward)
	feedback.Break(now)
	breakAt = now
	local rare = reward.valuableType ~= "Coal"
	kick, kickVelocity = rare and -12 or -8, 0
	local x, y = rock.sprite.x + 64, rock.sprite.y + 58
	for index = 1, 3 do
		local direction = index % 2 == 0 and -1 or 1
		Particle(
			x + direction * 24,
			y + index * 6,
			direction * (60 + index * 17),
			-95 - index * 12,
			0.48 + index * 0.025,
			pieces[index]
		)
		Particle(x - direction * 14, y + 22, -direction * (38 + index * 19), -50 - index * 8, 0.35)
	end
	if #drops >= 8 then
		visibleMoney += drops[1].value
		table.remove(drops, 1)
	end
	table.insert(drops, {
		x = x,
		y = y + 38,
		startX = x,
		startY = y + 38,
		age = 0,
		vx = impact % 2 == 0 and 115 or -115,
		value = reward.value,
		name = reward.valuableType,
		rare = rare,
	})
end

function scene.Find(collectable, discovered)
	visibleMoney += collectable.value
	if discovered then
		table.insert(finds, { name = collectable.collectableType, value = collectable.value, age = 0 })
	else
		pendingValue += collectable.value
		pendingName = pendingValue == collectable.value and collectable.collectableType or "Loot"
	end
end

function scene.Update(delta, change, canDrill, now)
	local speed = canDrill and math.min(1, math.abs(change) / math.max(1, delta * 420)) or 0
	activity += (speed - activity) * (1 - math.exp(-delta * (speed > activity and 18 or 9)))
	local turnSpeed = canDrill and math.max(-1440, math.min(1440, change / math.max(delta, 1 / 120))) or 0
	spin += (turnSpeed - spin) * (1 - math.exp(-delta * 22))
	phase = (phase + spin * delta / 24) % #drillFrames
	local target = 176 - activity * 10
	local steps = math.max(1, math.ceil(delta * 60))
	local step = delta / steps
	for _ = 1, steps do
		drillVelocity += ((target - drillY) * 180 - drillVelocity * 24) * step
		drillY = math.max(166, math.min(180, drillY + drillVelocity * step))
		kickVelocity += (-kick * 220 - kickVelocity * 18) * step
		kick += kickVelocity * step
	end
	for index = #particles, 1, -1 do
		local particle = particles[index]
		particle.age += delta
		particle.vy += delta * 340
		particle.x += particle.vx * delta
		particle.y += particle.vy * delta
		if particle.age >= particle.life then
			table.remove(particles, index)
		end
	end
	local collected, rare = pendingValue, false
	if collected > 0 then collectedName = pendingName end
	pendingValue, pendingName = 0, ""
	for index = #drops, 1, -1 do
		local drop = drops[index]
		drop.age += delta
		if drop.age < 0.48 then
			drop.x = drop.startX + drop.vx * drop.age
			drop.y = drop.startY - 70 * drop.age + 240 * drop.age * drop.age
		else
			local t = math.min(1, (drop.age - 0.48) / 0.38)
			local startX = drop.startX + drop.vx * 0.48
			local startY = drop.startY - 70 * 0.48 + 240 * 0.48 * 0.48
			local eased = t * t
			drop.x = startX + (29 - startX) * eased
			drop.y = startY + (12 - startY) * eased - math.sin(t * math.pi) * 30
		end
		if drop.age >= 0.86 then
			visibleMoney += drop.value
			collected += drop.value
			collectedName = collected == drop.value and drop.name or "Loot"
			rare = rare or drop.rare
			table.remove(drops, index)
		end
	end
	if collected > 0 then
		collectedAt = now
		collectedValue = collected
	end
	local findSound
	local find = finds[1]
	if find then
		local previousAge = find.age
		find.age += delta
		if previousAge < 0.12 and find.age >= 0.12 then
			findSound = "discovery"
		end
		if find.age >= 3.2 then
			table.remove(finds, 1)
		end
	end
	return collected, rare, findSound
end

local displayHeat = 0
local visualTargetHeat = 0

function scene.Draw(
	rock,
	values,
	heat,
	overheated,
	affordable,
	saveFailed,
	targetHeat,
	heatBuffer,
	activeHeat,
	rewardsTable,
	collectMult,
	rockCounter
)
	local now = pd.getCurrentTimeMilliseconds()

	local rockX, rockY, screenX, screenY, flashing = feedback.GetOffsets(now)
	gfx.clear(gfx.kColorBlack)
	gfx.setDrawOffset(screenX, screenY)
	background:draw(0, 0)
	gfx.setClipRect(48, 30, 304, 190)
	local rumble = activity > 0.1 and math.floor(math.sin(now * 0.11) * activity * 1.5) or 0
	local drill = pd.isCrankDocked() and hotDrill
		or activity > 0.08 and drillFrames[math.floor(phase) % #drillFrames + 1]
		or idleDrill
	local drillTop = math.floor(drillY + kick)
	local rodTop = drillTop + 46
	if rodTop < 220 then
		gfx.setColor(gfx.kColorBlack)
		gfx.fillRect(197 + rumble, rodTop, 6, 220 - rodTop)
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(199 + rumble, rodTop, 2, 220 - rodTop)
	end

	local age = now - breakAt
	local sprite = rock.sprite
	local frames = rockFrames[rock.rockType]
	if age < 75 then
		frames[#frames]:draw(sprite.x + rockX, sprite.y + rockY)
	elseif age >= 300 then
		local ratio = rock.health / rock.maxHealth
		local frame = 1
		if ratio <= 0.75 then
			frame = 2
		end
		if ratio <= 0.5 then
			frame = 3
		end
		if ratio <= 0.25 then
			frame = 4
		end

		local arrival = math.max(0, 1 - (age - 300) / 140)
		if flashing then
			gfx.setImageDrawMode(gfx.kDrawModeInverted)
		end
		frames[math.min(frame, #frames)]:draw(sprite.x + rockX, math.floor(sprite.y + rockY - arrival * arrival * 18))
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end
	drill:draw(184 + rumble, drillTop)
	for _, particle in ipairs(particles) do
		if particle.image then
			particle.image:drawRotated(math.floor(particle.x), math.floor(particle.y), particle.age * particle.vx * 3)
		else
			gfx.setColor(gfx.kColorBlack)
			gfx.fillRect(math.floor(particle.x), math.floor(particle.y), 3, 3)
		end
	end
	gfx.clearClipRect()
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(-6, -6, 412, 30)
	gfx.fillRect(-6, 220, 412, 26)
	local pulse = math.max(0, 1 - (now - collectedAt) / 180)
	local wallet = "$" .. visibleMoney
	if pulse > 0 then
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRoundRect(7, 0, body:getTextWidth(wallet) + 10, 24, 3)
	end
	Text(wallet, 12, 2 - pulse * 2, body, pulse == 0)
	local name = "< " .. rock.rockName .. " >"
	Text(name, 388 - body:getTextWidth(name), 2, body, true)

	--[[ 	gfx.setColor(gfx.kColorWhite)
	gfx.fillRoundRect(2, 27, 44, 39, 4)

	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect(2, 27, 44, 39, 4) ]]

	Text("ROKS'", 5, 30, small, true)
	Text(rockCounter, 5, 45, small, true)

	-- // SPEED BAR
	Text("SPE.", 17, 74, small, true)
	gfx.setColor(gfx.kColorWhite)
	gfx.drawRoundRect(28, 91, 12, 108, 3)

	displayHeat = displayHeat or 0
	displayHeat = displayHeat + (heat - displayHeat) * 0.15

	local fill = math.floor(math.min(1, displayHeat) * 102)
	gfx.fillRect(31, 196 - fill, 6, fill)

	-- // SPEED TARGET
	visualTargetHeat = visualTargetHeat or targetHeat
	visualTargetHeat = visualTargetHeat + (targetHeat - visualTargetHeat) * 0.1

	local calced = 108 / 100 * heatBuffer * 2
	local heatTargetVisualH = calced

	local heatMaxY = 91
	local heatMinY = 91 + 108

	local diff = heatMinY - heatMaxY
	local heatDiff = diff * (visualTargetHeat / 100)
	local curHeatY = heatMinY - heatDiff - heatBuffer

	if curHeatY < heatMaxY then
		local diff = heatMaxY - curHeatY
		curHeatY = heatMaxY
		heatTargetVisualH -= diff
	end

	local left = heatMinY - curHeatY
	if heatTargetVisualH > left then
		heatTargetVisualH = left
	end

	if not overheated then
		gfx.setColor(gfx.kColorWhite)
		gfx.drawRoundRect(26, curHeatY - 2, 16, heatTargetVisualH + 4, 4)

		gfx.setColor(gfx.kColorBlack)
		gfx.drawRoundRect(28, curHeatY, 12, heatTargetVisualH, 2)
	end

	-- // HEAT-BAR
	gfx.setColor(gfx.kColorWhite)
	gfx.drawRoundRect(4, 91, 14, 108, 3)

	local fill = math.floor(math.min(1, activeHeat / 100) * 102)
	gfx.fillRect(6, 199 - fill, 10, fill)

	Text("HEAT", 4, 203, small, true)

	Text("PWR:", 220, 6, small, true)
	local dmg = overheated and values.strength_mult * 2 or values.strength_mult
	Text(tostring(dmg), 255, 3, body, true)

	---@type RewardTable
	local tablee = rewardsTable
	local oreNames = { "Coal", "Topaz", "Diamond", "Emerald", "Ruby", "?" }
	Text("ODDS", 359, 27, small, true)

	for index, oreName in ipairs(oreNames) do
		local y = 45 + (index - 1) * 30
		local image = oreImages[oreName]

		gfx.setColor(gfx.kColorWhite)
		gfx.fillRoundRect(355, y - 1, 45, 24, 0)

		local t
		if image then
			image:drawScaled(355, y + 3, 0.5)
			for _, value in ipairs(tablee) do
				if value.valuableType == oreName then
					t = value.chance
					break
				end
			end
		else
			Text(oreName, 358, y + 3, body)
			t = collectMult
		end

		Text(t, 373, y + 4, small, false)
	end

	local hp = tostring(rock.health) .. "/" .. rock.maxHealth
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRoundRect(200 - small:getTextWidth(hp) / 2 - 7, 52, small:getTextWidth(hp) + 14, 21, 3)

	gfx.setColor(gfx.kColorWhite)
	gfx.fillRoundRect(200 - small:getTextWidth(hp) / 2 - 6, 53, small:getTextWidth(hp) + 12, 19, 3)

	Text(hp, 200 - small:getTextWidth(hp) / 2, 56, small)
	local prompt = affordable > 0 and "A Upgrades (" .. affordable .. ")" or "A Upgrades"
	Text(saveFailed and "Save failed" or prompt, 10, 224, small, true)
	gfx.setColor(gfx.kColorWhite)
	gfx.fillTriangle(196, 226, 204, 226, 200, 232)
	Text("Museum", 209, 224, small, true)
	Text("B Title", 350, 224, small, true)
	if not saveFailed and (overheated or pd.isCrankDocked()) then
		if overheated then
			local overheatText = "!OVERHEAT!"
			local drillText = "DRILL BABY DRILL"

			local overheatWidth = body:getTextWidth(overheatText)
			local drillWidth = small:getTextWidth(drillText)

			local boxWidth = math.max(overheatWidth, drillWidth) + 12
			local boxX = 200 - boxWidth / 2

			gfx.setColor(gfx.kColorWhite)
			gfx.fillRoundRect(boxX, 77, boxWidth, 49, 4)

			gfx.setColor(gfx.kColorBlack)
			gfx.drawRoundRect(boxX, 77, boxWidth, 49, 4)

			Text(overheatText, 200 - overheatWidth / 2, 82, body, false)

			local flash = math.floor(playdate.getCurrentTimeMilliseconds() / 100) % 2 == 0

			gfx.setColor(flash and gfx.kColorBlack or gfx.kColorWhite)
			gfx.fillRoundRect(200 - drillWidth / 2 - 4, 101, drillWidth + 8, 19, 3)

			gfx.setColor(flash and gfx.kColorWhite or gfx.kColorBlack)
			gfx.fillRoundRect(200 - drillWidth / 2 - 3, 102, drillWidth + 6, 17, 3)

			Text(drillText, 200 - drillWidth / 2, 103, small, true)
		else
			local hint = "Undock to drill"
			local width = small:getTextWidth(hint)
			Text(hint, 218 - width / 2, 254, small, true)
		end
	end
	if now - collectedAt < 850 then
		local text = "+$" .. collectedValue .. " " .. string.upper(collectedName)
		local x = math.max(88, body:getTextWidth(wallet) + 28)
		if x + small:getTextWidth(text) > 218 then text = "+$" .. collectedValue end
		Text(text, x, 5, small, true)
	end
	for _, drop in ipairs(drops) do
		local scale = drop.age <= 0.48 and 1 or math.max(0.3, 1 - (drop.age - 0.48) * 1.8)
		oreImages[drop.name]:drawScaled(math.floor(drop.x - 16 * scale), math.floor(drop.y - 16 * scale), scale)
		if drop.rare and drop.age < 0.48 then
			local radius = 20 + math.floor(math.sin(drop.age * 30) * 3)
			gfx.setColor(gfx.kColorBlack)
			gfx.drawLine(drop.x - radius - 3, drop.y, drop.x - radius + 3, drop.y)
			gfx.drawLine(drop.x, drop.y - radius - 3, drop.x, drop.y - radius + 3)
		end
	end

	gfx.setDrawOffset(0, 0)
	local find = finds[1]
	if find and find.age >= 0.12 then
		local duration = 3.2
		local enter = math.min(1, (find.age - 0.12) / 0.24)
		local leave = math.max(0, (find.age - duration + 0.22) / 0.22)
		local y = math.floor(31 - (1 - enter) ^ 3 * 125 - leave * leave * 125)
		gfx.setColor(gfx.kColorBlack)
		gfx.fillRoundRect(60, y + 4, 284, 84, 6)
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRoundRect(56, y, 284, 84, 6)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawRoundRect(56, y, 284, 84, 6)
		gfx.fillRoundRect(61, y + 5, 274, 20, 3)
		local label = "NEW COLLECTIBLE!"
		Text(label, 198 - small:getTextWidth(label) / 2, y + 8, small, true)
		Text(find.name, 198 - heading:getTextWidth(find.name) / 2, y + 29, heading)
		local detail = "+$" .. find.value .. "   Added to museum"
		Text(detail, 198 - small:getTextWidth(detail) / 2, y + 64, small)
		if find.age < 0.8 then
			local radius = 10 + (find.age - 0.12) * 26
			for side = -1, 1, 2 do
				local x = 198 + side * 125
				gfx.setColor(gfx.kColorBlack)
				gfx.drawLine(x - 5, y + 42, x + 5, y + 42)
				gfx.drawLine(x, y + 37, x, y + 47)
				gfx.setColor(gfx.kColorWhite)
				gfx.drawLine(x, y - radius, x, y - radius + 5)
			end
		end
	end
end

return scene
