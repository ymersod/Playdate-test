local pd <const> = playdate
local gfx <const> = pd.graphics
local feedback = import("modules/rockFeedback")
local scene = {}
local background = gfx.image.new("assets/textures/ui/backgroundMineshaftBlackBorderWhiteOutline")
local idleDrill = gfx.image.new("assets/textures/ui/drill"):scaledImage(0.75)
local hotDrill = gfx.image.new("assets/textures/ui/drill_blank"):scaledImage(0.75)
local drillFrames = {
	gfx.image.new("assets/textures/ui/drlil_animation1"),
	gfx.image.new("assets/textures/ui/drill_animation2"),
	gfx.image.new("assets/textures/ui/drill_animation3"),
	gfx.image.new("assets/textures/ui/drill_animation4"),
}
for index, image in ipairs(drillFrames) do
	drillFrames[index] = image:scaledImage(0.75)
end
local rockFrames = {
	gfx.image.new("assets/textures/stone1/stone1_default"),
	gfx.image.new("assets/textures/stone1/stone1_slightly_cracked"),
	gfx.image.new("assets/textures/stone1/stone1_cracked"),
	gfx.image.new("assets/textures/stone1/stone1_broken"),
}
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
local drillY, drillVelocity = 162, 0
local kick, kickVelocity = 0, 0
local activity, phase, spin = 0, 0, 0
local visibleMoney = 0
local collectedAt, collectedValue = -10000, 0
local collectedName = ""
local breakAt = -10000
local findAt = -10000
local findName = nil
local impact = 0

local collectablePopupCoroutines = {}

---@param collectable Collectable
local function startCollectablePopup(collectable)
	local collectablePopup = {
		text = tostring(collectable.collectableType),
		value = collectable.value,
		x = 300,
		y = 240,
		alpha = 0,
	}

	local routineKvP = {
		routine = nil,
		popupVals = collectablePopup,
	}

	local routine = coroutine.create(function()
		-- // SLIDE IN
		for i = 0, 1.5, 0.1 do
			collectablePopup.alpha = i
			collectablePopup.y = 240 - 30 * i
			coroutine.yield()
		end

		-- // HOLD
		for _ = 1, 45 do
			coroutine.yield()
		end

		-- // SLIDE OUT
		for i = 1.5, 0, -0.1 do
			collectablePopup.alpha = i
			collectablePopup.y = 240 - 30 * i
			coroutine.yield()
		end

		collectablePopup = nil
	end)
	routineKvP.routine = routine

	table.insert(collectablePopupCoroutines, routineKvP)
end

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
	drillY, drillVelocity = 162, 0
	kick, kickVelocity = 0, 0
	activity, phase, spin = 0, 0, 0
	visibleMoney = money
	collectedAt, breakAt, findAt = -10000, -10000, -10000
	collectedValue, findName = 0, nil
end

function scene.Hit(now, rock)
	feedback.Hit(now)
	breakAt = -10000
	kick, kickVelocity = -6, 0
	impact += 1
	local x = rock.sprite.x + 64
	local y = rock.sprite.y + 91
	for index = 1, 3 do
		local direction = (index + impact) % 2 == 0 and -1 or 1
		Particle(x + direction * 8, y, direction * (24 + index * 13), -24 - index * 12, 0.28 + index * 0.04)
	end
end

function scene.Break(now, rock, reward, collectable)
	feedback.Break(now)
	breakAt = now
	local rare = reward.valuableType ~= "Coal"
	kick, kickVelocity = rare and -30 or -23, 0
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

	if collectable then
		startCollectablePopup(collectable)
	end
end

function scene.Update(delta, change, canDrill, now)
	local speed = canDrill and math.min(1, math.abs(change) / math.max(1, delta * 420)) or 0
	activity += (speed - activity) * (1 - math.exp(-delta * (speed > activity and 18 or 9)))
	local turnSpeed = canDrill and math.max(-1440, math.min(1440, change / math.max(delta, 1 / 120))) or 0
	spin += (turnSpeed - spin) * (1 - math.exp(-delta * 22))
	phase = (phase + spin * delta / 24) % #drillFrames
	local target = 162 - activity * 30
	local steps = math.max(1, math.ceil(delta * 60))
	local step = delta / steps
	for _ = 1, steps do
		drillVelocity += ((target - drillY) * 180 - drillVelocity * 24) * step
		drillY = math.max(128, math.min(176, drillY + drillVelocity * step))
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
	local collected, rare = 0, false
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
			collectedName = collected == drop.value and drop.name or "Ore"
			rare = rare or drop.rare
			table.remove(drops, index)
		end
	end
	if collected > 0 then
		collectedAt = now
		collectedValue = collected
	end
	return collected, rare
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
	local rodTop = drillTop + 68
	if rodTop < 220 then
		gfx.setColor(gfx.kColorBlack)
		gfx.fillRect(197 + rumble, rodTop, 6, 220 - rodTop)
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(199 + rumble, rodTop, 2, 220 - rodTop)
	end

	drill:draw(176 + rumble, drillTop)
	local age = now - breakAt
	local sprite = rock.sprite
	if age < 75 then
		rockFrames[4]:draw(sprite.x + rockX, sprite.y + rockY)
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
		rockFrames[frame]:draw(sprite.x + rockX, math.floor(sprite.y + rockY - arrival * arrival * 18))
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end
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
		gfx.fillRoundRect(359, y - 1, 38, 24, 4)

		local t
		if image then
			image:drawScaled(361, y + 2, 0.5)
			for _, value in ipairs(tablee) do
				if value.valuableType == oreName then
					t = value.chance
					break
				end
			end
		else
			Text(oreName, 364, y + 3, body)
			t = collectMult
		end

		Text(t, 378, y + 3, small, false)
	end

	local hp = tostring(rock.health) .. "/" .. rock.maxHealth
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRoundRect(200 - small:getTextWidth(hp) / 2 - 7, 52, small:getTextWidth(hp) + 14, 21, 3)

	gfx.setColor(gfx.kColorWhite)
	gfx.fillRoundRect(200 - small:getTextWidth(hp) / 2 - 6, 53, small:getTextWidth(hp) + 12, 19, 3)

	Text(hp, 200 - small:getTextWidth(hp) / 2, 56, small)
	local prompt = affordable > 0 and "A Upgrades (" .. affordable .. ")" or "A Upgrades"
	Text(saveFailed and "Save failed - retry in Menu" or prompt, 10, 224, small, true)
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
	if now - findAt < 2200 or now - collectedAt < 850 then
		local found = now - findAt < 2200
		local text = found and "FOUND: " .. string.upper(findName)
			or "+$" .. collectedValue .. " " .. string.upper(collectedName)
		local x = math.max(88, body:getTextWidth(wallet) + 28)
		if x + small:getTextWidth(text) > 268 then
			text = found and string.upper(findName) or "+$" .. collectedValue
		end
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

	for index = #collectablePopupCoroutines, 1, -1 do
		local coroutineValue = collectablePopupCoroutines[index]
		local routine = coroutineValue.routine
		local popupVals = coroutineValue.popupVals
		local text = popupVals.text
		local value = popupVals.value
		local x = popupVals.x - 80

		local displayText = tostring(value) .. "$ " .. text .. " Found!"
		local textWidth = small:getTextWidth(displayText)
		local width = textWidth + 12

		local success = coroutine.resume(routine)

		gfx.setColor(gfx.kColorWhite)
		gfx.fillRoundRect(x, popupVals.y, width, 22, 4)

		gfx.setColor(gfx.kColorBlack)
		gfx.drawRoundRect(x, popupVals.y, width, 22, 4)

		Text(displayText, x + width / 2 - textWidth / 2, popupVals.y + 4, small)

		if not success or coroutine.status(routine) == "dead" then
			table.remove(collectablePopupCoroutines, index)
		end
	end

	gfx.setDrawOffset(0, 0)
end

return scene
