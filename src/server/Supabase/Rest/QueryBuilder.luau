--[[
	Main query builder that combines all query functionality.

	@module Rest.QueryBuilder
	@private
]]
local QueryBuilder = {}

local Http = game:GetService("HttpService")

-- Import modules
local Utils = require(script.Parent.Utils)
local QueryFilters = require(script.Parent.QueryFilters)
local QueryOperators = require(script.Parent.QueryOperators)
local QueryModifiers = require(script.Parent.QueryModifiers)
local QueryMutations = require(script.Parent.QueryMutations)

-- Re-export types for internal use
local Types = require(script.Parent.Types)
export type OrFilterOptions = Types.OrFilterOptions
export type TextSearchOptions = Types.TextSearchOptions
export type InsertOptions = Types.InsertOptions
export type UpdateOptions = Types.UpdateOptions
export type DeleteOptions = Types.DeleteOptions
export type RootQuery = Types.RootQuery

-- Track whether we've started using modifiers
local function createModifierWrapper(originalMethod, methodName)
    return function(self, ...)
        self._modifiersUsed = true
        return originalMethod(self, ...)
    end
end

-- Wrap filter methods to check if modifiers have already been used
local function createFilterWrapper(originalMethod)
    return function(self, ...)
        if self._modifiersUsed then
            error(string.format("Filter methods must be called before modifier methods. You cannot call a filter after using modifiers like single(), order(), limit(), etc."))
        end
        return originalMethod(self, ...)
    end
end

--[[
	Builds the HTTP request from the query configuration.

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
    elseif self.method == "POST" and self._insertOptions and self._insertOptions.returning then
        -- For insert/upsert, default to representation if not specified
        table.insert(preferHeaders, "return=" .. self._insertOptions.returning)
    elseif self.method == "PATCH" and self._updateOptions and self._updateOptions.returning then
        -- For update
        table.insert(preferHeaders, "return=" .. self._updateOptions.returning)
    elseif self.method == "DELETE" and self._deleteOptions and self._deleteOptions.returning then
        -- For delete
        table.insert(preferHeaders, "return=" .. self._deleteOptions.returning)
    end

    -- Handle count preference
    if self._insertOptions and self._insertOptions.count then
        table.insert(preferHeaders, "count=" .. self._insertOptions.count)
    elseif self._updateOptions and self._updateOptions.count then
        table.insert(preferHeaders, "count=" .. self._updateOptions.count)
    elseif self._deleteOptions and self._deleteOptions.count then
        table.insert(preferHeaders, "count=" .. self._deleteOptions.count)
    end

    -- Handle insert/upsert specific headers
    if self.method == "POST" and self._insertOptions then
        -- Handle onConflict for upsert
        if self._insertOptions.onConflict then
            local onConflict = self._insertOptions.onConflict
            if onConflict:find(",") then
                -- Multiple columns for onConflict
                onConflict = "(" .. onConflict .. ")"
            end
            table.insert(preferHeaders, "resolution=merge-duplicates")
            headers["Prefer"] = (headers["Prefer"] or "") .. ", on-conflict=" .. onConflict
        elseif self._insertOptions.ignoreDuplicates then
            table.insert(preferHeaders, "resolution=ignore-duplicates")
        elseif self._insertOptions.upsert then
            table.insert(preferHeaders, "resolution=merge-duplicates")
        end

        -- Handle defaultToNull
        if self._insertOptions.defaultToNull then
            table.insert(preferHeaders, "missing=default")
        end
    end

    -- Handle explain
    if self._explain then
        table.insert(preferHeaders, "explain=" .. self._explain)
    end

    -- Set Prefer header if we have any preferences
    if #preferHeaders > 0 then
        headers["Prefer"] = table.concat(preferHeaders, ", ")
    end

    -- Add Range headers for GET requests
    if self.method == "GET" and self.ranges then
        headers["Range-Unit"] = "items"
        for _, range in ipairs(self.ranges) do
            headers[range.key] = range.value
        end
    end

    local request = {
        Url = self.url .. self.query,
        Method = self.method or "GET",
        Headers = headers,
    }

    -- Add body for POST/PATCH requests
    if self.body and (self.method == "POST" or self.method == "PATCH") then
        request.Body = Http:JSONEncode(self.body)
    end

    return request
end

--[[
	Processes the response based on query configuration.

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
	Creates a new query builder instance.

	@param baseUrl string -- Base URL of the Supabase project
	@param key string -- API key
	@param tableName string -- Table name to query
	@param typesModule table? -- Optional types module for validation
	@return Query -- A new query builder instance
]]
function QueryBuilder.new(baseUrl, key, tableName, typesModule)
    local Query = {}
    Query.__index = Query

    --[[
		Specifies which columns to select from the table.

		@param columns string -- Comma-separated list of column names (use "*" for all columns)
		@return Query -- Returns self for method chaining
	]]
    function Query:select(columns: string)
        if not columns or columns == "" then
            columns = "*"
        end
        self.method = "GET"
        self.query = "?select=" .. Http:UrlEncode(columns)
        return self
    end

    --[[
		Executes the query and returns the results.

		@return any -- Query results (table, object, CSV string, boolean, or nil on error)
		@return string? -- Error message if request failed, nil otherwise
	]]
    function Query:execute()
        local req = buildRequest(self)
        local res = Http:RequestAsync(req)
        return processResponse(self, res)
    end

    --[[
		Executes the query and validates results against a runtime schema if available.

		@return any -- Query results (table, object, or nil on error)
		@return string? -- Error message if validation or request failed, nil otherwise
	]]
    function Query:executeTyped()
        local result, err = self:execute()
        if err then
            return nil, err
        end

        -- Handle minimal return (success boolean)
        if self._returns == "minimal" then
            return result, nil
        end

        -- Use override schema if provided, otherwise use module schema
        local schema = self._overrideSchema
        if not schema then
            local typesModule = self._typesModule
            if typesModule and typesModule.schemas and typesModule.schemas[self.table] then
                schema = typesModule.schemas[self.table]
            end
        end

        -- Validate if we have a schema
        if schema then
            -- Handle CSV response (no validation)
            if self._responseFormat == "csv" then
                return result, nil
            end

            -- Handle single object
            if self._expectSingle then
                if result ~= nil and not Utils.validateValue(result, schema) then
                    return nil, ("Result did not match schema for table '%s'"):format(self.table)
                end
                return result, nil
            end

            -- Handle array of rows (for insert/update/delete that return multiple rows)
            if type(result) == "table" then
                for idx, row in ipairs(result) do
                    if not Utils.validateValue(row, schema) then
                        return nil, ("Row %d did not match schema for table '%s'"):format(idx, self.table)
                    end
                end
            elseif result ~= nil then
                -- Unexpected response format
                return nil, "Unexpected response format for type validation"
            end
        end

        return result, nil
    end

    -- Combine all methods into the Query metatable
    local combinedMethods = {}

    -- Add QueryBuilder methods
    for k, v in pairs(Query) do
        combinedMethods[k] = v
    end

    -- Add QueryFilters methods with wrapper
    for k, v in pairs(QueryFilters) do
        combinedMethods[k] = createFilterWrapper(v)
    end

    -- Add QueryOperators methods with wrapper
    for k, v in pairs(QueryOperators) do
        combinedMethods[k] = createFilterWrapper(v)
    end

    -- Add QueryModifiers methods with wrapper
    for k, v in pairs(QueryModifiers) do
        combinedMethods[k] = createModifierWrapper(v, k)
    end

    -- Add QueryMutations methods
    for k, v in pairs(QueryMutations) do
        combinedMethods[k] = v
    end

    -- Create the final Query metatable with all combined methods
    local FinalQuery = {}
    FinalQuery.__index = combinedMethods

    local instance = setmetatable({
        url = baseUrl .. "/rest/v1/" .. tableName,
        key = key,
        query = "",
        table = tableName,
        _typesModule = typesModule,
        _modifiersUsed = false,
    }, FinalQuery)

    return instance
end

return QueryBuilder