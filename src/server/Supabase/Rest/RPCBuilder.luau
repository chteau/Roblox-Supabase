--[[
	RPC query builder for calling PostgreSQL functions.

	@module Rest.RPCBuilder
	@private
]]
local RPCBuilder = {}

local Http = game:GetService("HttpService")

-- Import modules
local QueryFilters = require(script.Parent.QueryFilters)
local QueryModifiers = require(script.Parent.QueryModifiers)

-- Re-export types
local Types = require(script.Parent.Types)
export type RPCQuery = Types.RPCQuery

-- Wrap filter methods to check if modifiers have already been used
local function createFilterWrapper(originalMethod)
    return function(self, ...)
        if self._modifiersUsed then
            error("Filter methods must be called before modifier methods. You cannot call a filter after using modifiers like single(), order(), limit(), etc.")
        end
        return originalMethod(self, ...)
    end
end

-- Track whether we've started using modifiers
local function createModifierWrapper(originalMethod, methodName)
    return function(self, ...)
        self._modifiersUsed = true
        return originalMethod(self, ...)
    end
end

--[[
	Builds the HTTP request from the RPC query configuration.

	@return table -- Request table for HttpService
	@private
]]
local function buildRequest(self)
    local headers = {
        ["apikey"] = self.key,
        ["Authorization"] = "Bearer " .. self.key,
        ["Content-Type"] = "application/json",
    }

    -- Add Accept header based on response format
    if self._responseFormat == "csv" then
        headers["Accept"] = "text/csv"
    elseif self._expectSingle and self._singleMode == "single" then
        headers["Accept"] = "application/vnd.pgrst.object+json"
    elseif self._expectSingle and self._singleMode == "maybeSingle" then
        headers["Accept"] = "application/vnd.pgrst.object+json"
    else
        headers["Accept"] = "application/json"
    end

    -- Build Prefer headers
    local preferHeaders = {}

    -- Handle returns preference
    if self._returns then
        table.insert(preferHeaders, "return=" .. self._returns)
    end

    -- Handle count preference
    if self._count then
        table.insert(preferHeaders, "count=" .. self._count)
    end

    -- Handle explain
    if self._explain then
        table.insert(preferHeaders, "explain=" .. self._explain)
    end

    -- Set Prefer header if we have any preferences
    if #preferHeaders > 0 then
        headers["Prefer"] = table.concat(preferHeaders, ", ")
    end

    -- Add Range headers for GET requests (when function returns a table)
    if self.method == "GET" and self.ranges then
        headers["Range-Unit"] = "items"
        for _, range in ipairs(self.ranges) do
            headers[range.key] = range.value
        end
    end

    local request = {
        Url = self.url .. self.query,
        Method = self.method or "POST",
        Headers = headers,
    }

    -- Add body for POST requests with parameters
    if self.body and self.method == "POST" then
        request.Body = Http:JSONEncode(self.body)
    end

    return request
end

--[[
	Processes the RPC response based on query configuration.

	@param response table -- HttpService response
	@return any -- Processed response
	@return string? -- Error message if any
	@private
]]
local function processResponse(self, response)
    if not response.Success then
        -- Try to decode Supabase error payload
        local okErr, errObj = pcall(function()
            if response.Body and response.Body ~= "" then
                return Http:JSONDecode(response.Body)
            end
            return nil
        end)

        if okErr and type(errObj) == "table" then
            local message = errObj.message or errObj.error_description or errObj.error or errObj.hint or errObj.details or response.StatusMessage
            return nil, ("Supabase error: %s"):format(tostring(message))
        end

        return nil, ("HTTP Request failed: %s"):format(tostring(response.StatusMessage))
    end

    -- Handle CSV response
    if self._responseFormat == "csv" then
        return response.Body, nil
    end

    -- Handle minimal return (no body expected)
    if self._returns == "minimal" then
        return true, nil
    end

    -- Handle empty response
    if response.Body == nil or response.Body == "" then
        return nil, nil
    end

    -- Handle JSON response
    local ok, decoded = pcall(function()
        return Http:JSONDecode(response.Body)
    end)

    if not ok then
        return nil, "Failed to parse JSON response"
    end

    -- Handle single/maybeSingle modes
    if self._expectSingle then
        if self._singleMode == "single" then
            if decoded == nil then
                return nil, "No rows returned"
            end

            -- Check if it's an empty array ([] vs {})
            if type(decoded) == "table" then
                local isArray = false
                local isEmpty = true
                local count = 0

                for k, v in pairs(decoded) do
                    isEmpty = false
                    if type(k) == "number" and math.floor(k) == k then
                        isArray = true
                    end
                    count = count + 1
                end

                -- If it's an empty array ([]), not an empty object ({})
                if isEmpty then
                    return nil, "No rows returned"
                end

                -- If it's an array with exactly one element
                if isArray and count == 1 and decoded[1] ~= nil then
                    return decoded[1], nil
                end
            end

            -- Otherwise, return the decoded object
            return decoded, nil
        elseif self._singleMode == "maybeSingle" then
            if decoded == nil then
                return nil, nil
            end

            -- Check if it's an empty array ([] vs {})
            if type(decoded) == "table" then
                local isArray = false
                local isEmpty = true
                local count = 0

                for k, v in pairs(decoded) do
                    isEmpty = false
                    if type(k) == "number" and math.floor(k) == k then
                        isArray = true
                    end
                    count = count + 1
                end

                -- If it's an empty array ([]), not an empty object ({})
                if isEmpty then
                    return nil, nil
                end

                -- If it's an array with exactly one element
                if isArray and count == 1 and decoded[1] ~= nil then
                    return decoded[1], nil
                end
            end

            -- Otherwise, return the decoded object
            return decoded, nil
        end
    end

    -- For normal queries, return the decoded response as-is
    return decoded, nil
end

--[[
	Creates a new RPC builder instance.

	@param baseUrl string -- Base URL of the Supabase project
	@param key string -- API key
	@param functionName string -- Function name to call
	@param params table? -- Optional parameters to pass to the function
	@param typesModule table? -- Optional types module for validation
	@return RPCQuery -- A new RPC builder instance
]]
function RPCBuilder.new(baseUrl, key, functionName, params, typesModule)
    local RPCQuery = {}
    RPCQuery.__index = RPCQuery

    --[[
        Executes the RPC call and returns the results.

        @return any -- Query results (table, object, CSV string, boolean, or nil on error)
        @return string? -- Error message if request failed, nil otherwise
    ]]
    function RPCQuery:execute()
        local req = buildRequest(self)
        local res = Http:RequestAsync(req)
        return processResponse(self, res)
    end

    --[[
        Executes the RPC call and validates results against a runtime schema if available.

        @return any -- Query results (table, object, or nil on error)
        @return string? -- Error message if validation or request failed, nil otherwise
    ]]
    function RPCQuery:executeTyped()
        local result, err = self:execute()
        if err then
            return nil, err
        end

        -- Handle minimal return (success boolean)
        if self._returns == "minimal" then
            return result, nil
        end

        -- Type validation would go here if needed
        return result, nil
    end

    --[[
        Sets parameters for the RPC call (optional).

        @param params table -- Parameters to pass to the function
        @return RPCQuery -- Returns self for method chaining
    ]]
    function RPCQuery:params(paramsTable)
        self.body = paramsTable
        self.method = "POST"
        return self
    end

    --[[
        Uses GET method instead of POST for the RPC call.
        Useful for functions that don't require parameters or are marked as IMMUTABLE.

        @return RPCQuery -- Returns self for method chaining
    ]]
    function RPCQuery:get()
        self.method = "GET"
        return self
    end

    -- Combine all methods into the RPCQuery metatable
    local combinedMethods = {}

    -- Add RPCQuery methods
    for k, v in pairs(RPCQuery) do
        combinedMethods[k] = v
    end

    -- Add QueryFilters methods with wrapper
    for k, v in pairs(QueryFilters) do
        combinedMethods[k] = createFilterWrapper(v)
    end

    -- Add QueryModifiers methods with wrapper
    for k, v in pairs(QueryModifiers) do
        combinedMethods[k] = createModifierWrapper(v, k)
    end

    -- Create the final RPCQuery metatable with all combined methods
    local FinalRPCQuery = {}
    FinalRPCQuery.__index = combinedMethods

    local instance = setmetatable({
        url = baseUrl .. "/rest/v1/rpc/" .. functionName,
        key = key,
        query = "",
        functionName = functionName,
        body = params,
        method = params and "POST" or "GET",
        _typesModule = typesModule,
        _modifiersUsed = false,
    }, FinalRPCQuery)

    return instance
end

return RPCBuilder