---@class Museum
local museum = {}

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
			return
		end
	end

	table.insert(collectablesOwned, collectable)
end

---@param toSetCollectableList CollectableList
function museum.Start(toSetCollectableList)
	collectableList = toSetCollectableList
end

return museum
