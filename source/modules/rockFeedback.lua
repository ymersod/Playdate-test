local feedback = {}
local hitAt = -1000
local breakAt = -1000
local direction = 1
local stepTime = 30
local hitSteps = { { 3, -1 }, { -2, 1 }, { 1, -1 }, { -1, 0 } }
local breakSteps = { { -5, 3 }, { 4, -3 }, { -3, -2 }, { 2, 2 }, { -2, -1 }, { 1, 1 }, { -1, 0 } }

local function Offset(steps, age)
	local step = age >= 0 and steps[math.floor(age / stepTime) + 1]
	if step then return step[1], step[2] end
	return 0, 0
end

function feedback.Hit(now)
	hitAt = now
	direction = -direction
end

function feedback.Break(now)
	hitAt = -1000
	breakAt = now
end

function feedback.Reset()
	hitAt = -1000
	breakAt = -1000
end

function feedback.GetOffsets(now)
	local rockX, rockY = Offset(hitSteps, now - hitAt)
	local screenX, screenY = Offset(breakSteps, now - breakAt)
	local flashing = now >= hitAt and now - hitAt < 90
	return rockX * direction, rockY, screenX, screenY, flashing
end

return feedback
