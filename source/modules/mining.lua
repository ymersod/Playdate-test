---@class MineRock
local mining = {}

local heat = 0
local overheated = false

function mining.Reset()
	heat = 0
	overheated = true
end

function mining.GetHeat()
	return heat, overheated
end

local playerRotationSpeed = 0
local rpsMover = 0.0
local heatBarMoveSmoothing = 10
local playerRotationAcceleration = 80

---@param rotationDelta number
---@param delta number
function mining.UpdateRPSBar(rotationDelta, delta)
	rotationDelta = math.abs(rotationDelta)

	-- // PLAYER RPS
	local targetRps = rotationDelta / (360 * delta)
	local rpsDifference = targetRps - playerRotationSpeed
	local maxChange = playerRotationAcceleration * delta

	playerRotationSpeed += math.max(-maxChange, math.min(maxChange, rpsDifference))

	-- // HEAT MOVER
	local targetMover = math.max(0, math.min(playerRotationSpeed / 5, 1))

	if rpsMover then
		local heatInc = (targetMover - rpsMover) / heatBarMoveSmoothing
		rpsMover += heatInc
	end

	-- // HEAT
	--[[ playerHeat += playerRotationSpeed * heatRate * delta
	playerHeat = math.max(0, math.min(playerHeat, 100)) ]]

	return rpsMover
end

---@param heatToMatch number
---@param heatsinks_mult number
---@param rpsMover number
---@param heatBuffer number
---@return boolean
function mining.IsInHeatZone(heatToMatch, heatsinks_mult, rpsMover, heatBuffer)
	local multed_buffer = heatBuffer + heatsinks_mult
	local scaledMover = rpsMover * 100

	local heatMin = heatToMatch - multed_buffer
	local heatMax = heatToMatch + multed_buffer

	if scaledMover >= heatMin and scaledMover <= heatMax then
		return true
	end

	return false
end

local heat_zone_speed = 10
---@param isInHeatZone boolean
---@param delta number
---@return number, boolean
function mining.UpdateHeat(isInHeatZone, delta)
	local increment = heat_zone_speed * delta
	if overheated then
		increment = increment * 1.5
	end

	if not isInHeatZone or overheated then
		increment = -increment
	end

	heat += increment

	if heat < 0 then
		heat = 0
		overheated = false
	elseif heat > 100 then
		heat = 100
		overheated = true
	end

	return mining.GetHeat()
end

---@param tick number
---@param rock RockGeneric?
---@param strength_mult number
---@param overheated boolean
function mining.Mine(tick, rock, strength_mult, heatsinks_mult, overheated)
	local dmg = strength_mult
	if overheated then
		dmg = dmg * 2
	end

	if not rock or tick < 1 or rock.health <= 0 then
		return 0
	end
	local hits = 0
	for _ = 1, tick do
		rock.health = math.max(0, rock.health - dmg)
		hits += 1
		if rock.health == 0 then
			break
		end
	end
	return hits
end

return mining
