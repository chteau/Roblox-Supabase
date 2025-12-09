--[[
	Utility functions for the Supabase REST client.

	@module Rest.Utils
	@private
]]
local Utils = {}

--[[
	Attempts to load user-provided type definitions from a `Database.Types` ModuleScript.

	@param scriptRoot Instance? -- The script root to search from
	@return table? -- Loaded types module or nil if not found
]]
function Utils.tryLoadTypes(scriptRoot)
    local candidates = {}
    if scriptRoot then
        table.insert(candidates, scriptRoot:FindFirstChild("Database.Types"))
        if scriptRoot.Parent then
            table.insert(candidates, scriptRoot.Parent:FindFirstChild("Database.Types"))
            if scriptRoot.Parent.Parent then
                table.insert(candidates, scriptRoot.Parent.Parent:FindFirstChild("Database.Types"))
            end
        end
    end

    for _, candidate in ipairs(candidates) do
        if candidate then
            local ok, mod = pcall(require, candidate)
            if ok and type(mod) == "table" then
                return mod
            end
        end
    end

    return nil
end

--[[
	Validates a value against an expected type definition.

	@param value any -- The value to validate
	@param expected any -- Expected type definition
	@return boolean -- True if value matches expected type
]]
function Utils.validateValue(value, expected)
    local t = type(value)
    if expected == "any" then
        return true
    end
    if type(expected) == "string" then
        return t == expected
    end
    if type(expected) == "table" then
        if t ~= "table" then return false end
        for k, v in pairs(expected) do
            if not Utils.validateValue(value[k], v) then
                return false
            end
        end
        return true
    end
    return false
end

return Utils