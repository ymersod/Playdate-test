---@type TestHelper
local testHelper = import("helpers/testHelper")
import("CoreLibs/object")

function playdate.update()
	local testVar = 3
	print("Hello world " .. testVar)
end

print(testHelper.Call(5))
