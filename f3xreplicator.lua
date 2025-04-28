--[[
	ModuleScript: F3XReplicator
	Location: ReplicatedStorage (or another client-accessible location)
	Description: A more advanced client-sided library to simplify F3X replication calls,
	             including action name encoding based on AccountAge and dynamic remote finding.
--]]

local F3XReplicator = {}

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace") -- Potentially useful for part finding outside the module

-- Private Variables
local localPlayer = Players.LocalPlayer

-- Base action names (before encoding)
local BASE_ACTION_NAMES = {
	Color = "SyncColor",
	Rotate = "SyncRotate",
	Create = "CreatePart",
	Material = "SyncMaterial", -- Used for both Material and Reflectance
	Reflectance = "SyncMaterial",
}

--[[-------------------------------------------------------------------------
	Encoding Function (as provided)
---------------------------------------------------------------------------]]
local function shift_string(input_str, shift_amount)
	local result_chars = {}
	for _, char_code in utf8.codes(input_str) do
		-- Ensure shift_amount is treated as a number
		local numeric_shift_amount = tonumber(shift_amount) or 0
		local shifted_code = char_code + numeric_shift_amount
		table.insert(result_chars, utf8.char(shifted_code))
	end
	return table.concat(result_chars)
end

--[[-------------------------------------------------------------------------
	Helper Functions
---------------------------------------------------------------------------]]

-- Function to get the current shift amount (AccountAge)
local function getShiftAmount()
	if not localPlayer then
		localPlayer = Players.LocalPlayer -- Attempt to get if not initially available
		if not localPlayer then
			warn("F3XReplicator: Cannot get LocalPlayer to determine AccountAge shift.")
			return nil
		end
	end
	-- The '+ 0' is technically redundant but included as per your snippet
	return localPlayer.AccountAge + 0
end

-- Function to find the F3X remote function dynamically from the equipped tool
local function findRemoteFunction()
	if not localPlayer then
		localPlayer = Players.LocalPlayer
		if not localPlayer then
			warn("F3XReplicator: Cannot find LocalPlayer.")
			return nil
		end
	end

	local character = localPlayer.Character
	if not character then
		-- Don't wait indefinitely here, the tool should be equipped when action is called
		warn("F3XReplicator: Cannot find Character.")
		return nil
	end

	-- Find the equipped F3X tool
	-- This assumes the F3X tool is the currently equipped tool or the first one found.
	-- Adjust logic if multiple tools can be equipped or naming is more specific.
	local tool = character:FindFirstChildWhichIsA("Tool")
	if not tool then
		warn("F3XReplicator: No Tool found equipped on the character. Cannot find RemoteFunction.")
		return nil
	end

	-- Navigate to the RemoteFunction as per the specified path
	local bindable = tool:FindFirstChildOfClass("BindableFunction")
	if not bindable then
		warn("F3XReplicator: Could not find BindableFunction in Tool:", tool.Name)
		return nil
	end

	local remote = bindable:FindFirstChildOfClass("RemoteFunction")
	if not remote then
		warn("F3XReplicator: Could not find RemoteFunction within BindableFunction in Tool:", tool.Name)
		return nil
	end

	return remote
end

-- Internal function to safely find remote, encode action, and invoke
-- Expects the actionKey (e.g., "Color", "Rotate") and the subsequent arguments
-- exactly as they should be passed to InvokeServer (after the encoded action name).
local function invokeRemote(actionKey, ...)
	local remote = findRemoteFunction()
	if not remote then
		return false, "Could not find F3X RemoteFunction (is tool equipped?)"
	end

	local shiftAmount = getShiftAmount()
	if shiftAmount == nil then -- Check for nil explicitly
		return false, "Could not determine shift amount (LocalPlayer issue?)"
	end

	local baseActionName = BASE_ACTION_NAMES[actionKey]
	if not baseActionName then
		warn("F3XReplicator: Invalid internal action key provided:", actionKey)
		return false, "Invalid internal action key"
	end

	-- Encode the action name
	local encodedActionName = shift_string(baseActionName, shiftAmount)

	-- Prepare the final arguments table for InvokeServer
	local invokeArgs = { encodedActionName, ... } -- Pack the encoded name and the rest of the arguments

	-- Debug: Print arguments before invoking (optional)
	-- print("F3XReplicator Invoking:", invokeArgs[1], "with data:", {select(2, unpack(invokeArgs))})

	-- Safely invoke the server
	local success, result = pcall(function()
		-- Unpack the prepared arguments table
		return remote:InvokeServer(unpack(invokeArgs))
	end)

	if not success then
		warn("F3XReplicator: Error invoking F3X action '", baseActionName, "' (encoded as '", encodedActionName, "'):", result)
		return false, result -- Return the error message
	end

	-- Return true (for success) and any value returned by InvokeServer (if applicable)
	return true, result
end

--[[-------------------------------------------------------------------------
	Public API Functions
---------------------------------------------------------------------------]]

--- Sets the color of one or more parts using F3X replication.
-- @param partsInfo table An array of tables, each containing { Part = Instance, Color = Color3 }.
-- Example: { { Part = workspace.Part1, Color = Color3.new(1,0,0) } }
-- Example: { { Part = p1, Color = c1 }, { Part = p2, Color = c2 } }
-- @return boolean success, any resultOrError
function F3XReplicator.SetColor(partsInfo)
	if type(partsInfo) ~= "table" then
		warn("F3XReplicator.SetColor: Invalid partsInfo format. Expected table, got:", type(partsInfo))
		return false, "Invalid partsInfo format"
	end

	local formattedPartsData = {}
	for i, data in ipairs(partsInfo) do
		if type(data) == "table" and data.Part and data.Color then
			table.insert(formattedPartsData, {
				["Part"] = data.Part,
				["Color"] = data.Color,
				["UnionColoring"] = true -- Hardcoded as per requirement
			})
		else
			warn("F3XReplicator.SetColor: Skipping invalid entry #"..tostring(i).." in partsInfo.")
		end
	end

	if #formattedPartsData == 0 then
		return false, "No valid part data provided for SetColor"
	end

	-- The second argument for SyncColor is a table containing the list of part data tables
	return invokeRemote("Color", formattedPartsData)
end

--- Rotates one or more parts using F3X replication.
-- @param partsInfo table An array of tables, each containing { Part = Instance, CFrame = CFrame }.
-- Example: { { Part = workspace.Part1, CFrame = CFrame.new(...) } }
-- Example: { { Part = p1, CFrame = cf1 }, { Part = p2, CFrame = cf2 } }
-- @return boolean success, any resultOrError
function F3XReplicator.Rotate(partsInfo)
	if type(partsInfo) ~= "table" then
		warn("F3XReplicator.Rotate: Invalid partsInfo format. Expected table, got:", type(partsInfo))
		return false, "Invalid partsInfo format"
	end

	local formattedPartsData = {}
	for i, data in ipairs(partsInfo) do
		if type(data) == "table" and data.Part and data.CFrame then
			table.insert(formattedPartsData, {
				["Part"] = data.Part,
				["CFrame"] = data.CFrame
			})
		else
			warn("F3XReplicator.Rotate: Skipping invalid entry #"..tostring(i).." in partsInfo.")
		end
	end

	if #formattedPartsData == 0 then
		return false, "No valid part data provided for Rotate"
	end

	-- The second argument for SyncRotate is a table containing the list of part data tables
	return invokeRemote("Rotate", formattedPartsData)
end

--- Creates a new part using F3X replication.
-- @param shapeType string The type of part to create (e.g., "Ball", "Part", "WedgePart").
-- @param cframe CFrame The position and orientation for the new part.
-- @return boolean success, any resultOrError
function F3XReplicator.CreatePart(shapeType, cframe)
	if type(shapeType) ~= "string" or type(cframe) ~= "userdata" or typeof(cframe) ~= "CFrame" then
		warn("F3XReplicator.CreatePart: Invalid arguments. Expected string (shapeType) and CFrame.")
		return false, "Invalid arguments for CreatePart"
	end

	-- Arguments for CreatePart are: encodedActionName, shapeType (string), cframe (CFrame)
	return invokeRemote("Create", shapeType, cframe)
end

--- Sets the material of one or more parts using F3X replication.
-- @param partsInfo table An array of tables, each containing { Part = Instance, Material = Enum.Material }.
-- Example: { { Part = workspace.Part1, Material = Enum.Material.Plastic } }
-- Example: { { Part = p1, Material = m1 }, { Part = p2, Material = m2 } }
-- @return boolean success, any resultOrError
function F3XReplicator.SetMaterial(partsInfo)
	if type(partsInfo) ~= "table" then
		warn("F3XReplicator.SetMaterial: Invalid partsInfo format. Expected table, got:", type(partsInfo))
		return false, "Invalid partsInfo format"
	end

	local formattedPartsData = {}
	for i, data in ipairs(partsInfo) do
		-- Check if Material is specifically provided (don't include Reflectance here)
		if type(data) == "table" and data.Part and data.Material then
			table.insert(formattedPartsData, {
				["Part"] = data.Part,
				["Material"] = data.Material
				-- ["Reflectance"] = nil -- Ensure reflectance isn't accidentally carried over if reusing tables
			})
		else
			warn("F3XReplicator.SetMaterial: Skipping invalid entry #"..tostring(i).." in partsInfo (requires Part and Material).")
		end
	end

	if #formattedPartsData == 0 then
		return false, "No valid part data provided for SetMaterial"
	end

	-- The second argument for SyncMaterial (when setting material) is a table containing the list of part data tables
	return invokeRemote("Material", formattedPartsData)
end

--- Sets the reflectance of one or more parts using F3X replication.
-- @param partsInfo table An array of tables, each containing { Part = Instance, Reflectance = number }.
-- Example: { { Part = workspace.Part1, Reflectance = 0.5 } }
-- Example: { { Part = p1, Reflectance = r1 }, { Part = p2, Reflectance = r2 } }
-- Note: Your example used -100, which is outside the typical 0-1 range. The module passes it as-is.
-- @return boolean success, any resultOrError
function F3XReplicator.SetReflectance(partsInfo)
	if type(partsInfo) ~= "table" then
		warn("F3XReplicator.SetReflectance: Invalid partsInfo format. Expected table, got:", type(partsInfo))
		return false, "Invalid partsInfo format"
	end

	local formattedPartsData = {}
	for i, data in ipairs(partsInfo) do
		-- Check if Reflectance is specifically provided (don't include Material here)
		if type(data) == "table" and data.Part and data.Reflectance ~= nil then -- Allow 0 reflectance
			table.insert(formattedPartsData, {
				["Part"] = data.Part,
				["Reflectance"] = data.Reflectance
				-- ["Material"] = nil -- Ensure material isn't accidentally carried over
			})
		else
			warn("F3XReplicator.SetReflectance: Skipping invalid entry #"..tostring(i).." in partsInfo (requires Part and Reflectance).")
		end
	end

	if #formattedPartsData == 0 then
		return false, "No valid part data provided for SetReflectance"
	end

	-- The second argument for SyncMaterial (when setting reflectance) is a table containing the list of part data tables
	return invokeRemote("Reflectance", formattedPartsData)
end

--[[
-- TODO: Add functions for other actions like Resize, Move, Delete etc.
-- You would need to:
-- 1. Add their base action names to BASE_ACTION_NAMES.
-- 2. Determine the correct structure for the arguments table (the `...` part passed to invokeRemote).
-- 3. Create a public function similar to the ones above.

function F3XReplicator.Resize(partsInfo)
	-- Determine expected partsInfo structure (e.g., { { Part=p, Size=s, CFrame=cf }, ...} ?)
	-- Format data appropriately
	-- return invokeRemote("Resize", formattedData)
	warn("F3XReplicator.Resize is not yet implemented.")
	return false, "Not implemented"
end
--]]


return F3XReplicator
