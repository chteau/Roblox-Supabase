local Http = game:GetService("HttpService")

--[[
	The main REST client class for interacting with Supabase PostgREST API.

	@class Rest
	@client
]]
local Rest = {}
Rest.__index = Rest

--[[
	Options for the `or_` filter method.

	@within Rest
	@prop foreignTable string? -- Optional foreign table name for the filter
]]
export type OrFilterOptions = {
    foreignTable: string?,
}

--[[
	Options for text search operations.

	@within Rest
	@prop config string? -- Text search configuration
	@prop type "plain" | "phrase" | "websearch" -- Type of text search to perform
]]
export type TextSearchOptions = {
    config: string?,
    type: "plain" | "phrase" | "websearch",
}

--[[
	A query builder interface for constructing database queries.

	@within Rest
	@prop select (self: Query, columns: string) -> Query -- Select specific columns
	@prop eq (self: Query, column: string, value: any) -> Query -- Equality filter
	@prop neq (self: Query, column: string, value: any) -> Query -- Inequality filter
	@prop gt (self: Query, column: string, value: any) -> Query -- Greater than filter
	@prop gte (self: Query, column: string, value: any) -> Query -- Greater than or equal filter
	@prop lt (self: Query, column: string, value: any) -> Query -- Less than filter
	@prop lte (self: Query, column: string, value: any) -> Query -- Less than or equal filter
	@prop like (self: Query, column: string, pattern: string) -> Query -- LIKE pattern match
	@prop ilike (self: Query, column: string, pattern: string) -> Query -- Case-insensitive LIKE
	@prop is (self: Query, column: string, value: boolean | "null") -> Query -- IS NULL or IS TRUE/FALSE
	@prop in_ (self: Query, column: string, values: {any}) -> Query -- IN list filter
	@prop contains (self: Query, column: string, value: any) -> Query -- Contains filter
	@prop containedBy (self: Query, column: string, value: any) -> Query -- Contained by filter
	@prop rangeGt (self: Query, column: string, range: string) -> Query -- Range strictly right of
	@prop rangeGte (self: Query, column: string, range: string) -> Query -- Range does not extend left of
	@prop rangeLt (self: Query, column: string, range: string) -> Query -- Range strictly left of
	@prop rangeLte (self: Query, column: string, range: string) -> Query -- Range does not extend right of
	@prop rangeAdjacent (self: Query, column: string, range: string) -> Query -- Range adjacent to
	@prop overlaps (self: Query, column: string, value: any) -> Query -- Range overlaps
	@prop match (self: Query, query: {[string]: any}) -> Query -- Multiple equality filters
	@prop not_ (self: Query, column: string, operator: string, value: any) -> Query -- Negated filter
	@prop filter (self: Query, column: string, operator: string, value: any) -> Query -- Generic filter
	@prop or_ (self: Query, filters: string, options: OrFilterOptions) -> Query -- OR filter
	@prop textSearch (self: Query, column: string, query: string, options: TextSearchOptions) -> Query -- Full-text search
	@prop single (self: Query) -> Query -- Limit to single result
	@prop execute (self: Query) -> any -- Execute query (untyped)
	@prop executeTyped (self: Query) -> any -- Execute query with type validation
]]
export type Query = {
    select: (self: Query, columns: string) -> Query,
    eq: (self: Query, column: string, value: any) -> Query,
    neq: (self: Query, column: string, value: any) -> Query,
    gt: (self: Query, column: string, value: any) -> Query,
    gte: (self: Query, column: string, value: any) -> Query,
    lt: (self: Query, column: string, value: any) -> Query,
    lte: (self: Query, column: string, value: any) -> Query,
    like: (self: Query, column: string, pattern: string) -> Query,
    ilike: (self: Query, column: string, pattern: string) -> Query,
    is: (self: Query, column: string, value: boolean | "null") -> Query,
    in_: (self: Query, column: string, values: {any}) -> Query,
    contains: (self: Query, column: string, value: any) -> Query,
    containedBy: (self: Query, column: string, value: any) -> Query,
    rangeGt: (self: Query, column: string, range: string) -> Query,
    rangeGte: (self: Query, column: string, range: string) -> Query,
    rangeLt: (self: Query, column: string, range: string) -> Query,
    rangeLte: (self: Query, column: string, range: string) -> Query,
    rangeAdjacent: (self: Query, column: string, range: string) -> Query,
    overlaps: (self: Query, column: string, value: any) -> Query,
    match: (self: Query, query: {[string]: any}) -> Query,
    not_: (self: Query, column: string, operator: string, value: any) -> Query,
    filter: (self: Query, column: string, operator: string, value: any) -> Query,
    or_: (self: Query, filters: string, options: OrFilterOptions) -> Query,
    textSearch: (self: Query, column: string, query: string, options: TextSearchOptions) -> Query,
    single: (self: Query) -> Query,
    execute: (self: Query) -> any,
    executeTyped: (self: Query) -> any,
}

--[[
	Main REST client for Supabase PostgREST API.

	@within Rest
	@prop from (self: RestClient, tableName: string) -> Query -- Create query for specific table
]]
export type RestClient = {
    from: (self: RestClient, tableName: string) -> Query,
}

--[[
	Attempts to load user-provided type definitions from a `Database.Types` ModuleScript.

	@param scriptRoot Instance? -- The script root to search from
	@return table? -- Loaded types module or nil if not found
	@private
]]
local function tryLoadTypes(scriptRoot)
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
	@private
]]
local function validateValue(value, expected)
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
            if not validateValue(value[k], v) then
                return false
            end
        end
        return true
    end
    return false
end

--[[
	Creates a new Supabase REST client.

	@param baseUrl string -- The base URL of your Supabase project
	@param key string -- Your Supabase API key (anon key)
	@return RestClient -- A new REST client instance

	@example
	local supabase = Rest.new("https://your-project.supabase.co", "your-anon-key")
]]
function Rest.new(baseUrl: string, key: string): RestClient
    local self = setmetatable({}, Rest)

    self.baseUrl = baseUrl
    self.key = key
    -- Attempt to load types from a `Database.Types` module placed near this script.
    self._typesModule = tryLoadTypes(script)

    return (self :: any) :: RestClient
end

--[[
	Creates a query builder for a specific table.

	@param tableName string -- The name of the table to query
	@return Query -- A query builder instance for the specified table

	@example
	local query = supabase:from("users")
		:select("*")
		:eq("status", "active")
		:execute()
]]
function Rest:from(tableName: string)
    local Query = {}
    Query.__index = Query

    --[[
		Specifies which columns to select from the table.

		@param columns string -- Comma-separated list of column names (use "*" for all columns)
		@return Query -- Returns self for method chaining

		@example
		:select("id,name,email")
		:select("*") -- Select all columns
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
		Adds an equality filter (equals).

		@param column string -- Column name to filter
		@param value any -- Value to compare against
		@return Query -- Returns self for method chaining

		@example
		:eq("status", "active")
	]]
    function Query:eq(column: string, value: any)
        return self:filter(column, "eq", value)
    end

    --[[
		Adds an inequality filter (not equals).

		@param column string -- Column name to filter
		@param value any -- Value to compare against
		@return Query -- Returns self for method chaining

		@example
		:neq("status", "inactive")
	]]
    function Query:neq(column: string, value: any)
        return self:filter(column, "neq", value)
    end

    --[[
		Adds a greater than filter.

		@param column string -- Column name to filter
		@param value any -- Value to compare against
		@return Query -- Returns self for method chaining

		@example
		:gt("age", 18)
	]]
    function Query:gt(column: string, value: any)
        return self:filter(column, "gt", value)
    end

    --[[
		Adds a greater than or equal filter.

		@param column string -- Column name to filter
		@param value any -- Value to compare against
		@return Query -- Returns self for method chaining

		@example
		:gte("score", 100)
	]]
    function Query:gte(column: string, value: any)
        return self:filter(column, "gte", value)
    end

    --[[
		Adds a less than filter.

		@param column string -- Column name to filter
		@param value any -- Value to compare against
		@return Query -- Returns self for method chaining

		@example
		:lt("age", 65)
	]]
    function Query:lt(column: string, value: any)
        return self:filter(column, "lt", value)
    end

    --[[
		Adds a less than or equal filter.

		@param column string -- Column name to filter
		@param value any -- Value to compare against
		@return Query -- Returns self for method chaining

		@example
		:lte("price", 99.99)
	]]
    function Query:lte(column: string, value: any)
        return self:filter(column, "lte", value)
    end

    --[[
		Adds a LIKE pattern match filter (case-sensitive).

		@param column string -- Column name to filter
		@param pattern string -- SQL LIKE pattern (use % as wildcard)
		@return Query -- Returns self for method chaining

		@example
		:like("name", "John%") -- Starts with John
		:like("email", "%@gmail.com") -- Ends with @gmail.com
	]]
    function Query:like(column: string, pattern: string)
        return self:filter(column, "like", pattern)
    end

    --[[
		Adds a case-insensitive LIKE pattern match filter.

		@param column string -- Column name to filter
		@param pattern string -- SQL LIKE pattern (use % as wildcard)
		@return Query -- Returns self for method chaining

		@example
		:ilike("name", "john%") -- Case-insensitive match
	]]
    function Query:ilike(column: string, pattern: string)
        return self:filter(column, "ilike", pattern)
    end

    --[[
		Adds an IS NULL or IS TRUE/FALSE filter.

		@param column string -- Column name to filter
		@param value boolean | "null" -- Value to compare against (true, false, or "null")
		@return Query -- Returns self for method chaining

		@example
		:is("deleted_at", "null") -- IS NULL
		:is("active", true) -- IS TRUE
	]]
    function Query:is(column: string, value: boolean | "null")
        return self:filter(column, "is", value)
    end

    --[[
		Adds an IN list filter to match against multiple values.

		@param column string -- Column name to filter
		@param values {any} -- Array of values to match against
		@return Query -- Returns self for method chaining

		@example
		:in_("status", {"active", "pending", "approved"})
	]]
    function Query:in_(column: string, values: {any})
        local key = Http:UrlEncode(tostring(column))
        local encodedValues = {}
        for _, v in ipairs(values) do
            local valStr = tostring(v)
            -- As per PostgREST docs, strings containing commas must be double-quoted.
            if type(v) == "string" and valStr:find(",", 1, true) then
                table.insert(encodedValues, ('"%s"'):format(valStr))
            else
                table.insert(encodedValues, Http:UrlEncode(valStr))
            end
        end
        local filterStr = key .. "=in.(" .. table.concat(encodedValues, ",") .. ")"
        if not self.query or self.query == "" then
            self.query = "?" .. filterStr
        else
            self.query = self.query .. "&" .. filterStr
        end
        return self
    end

    --[[
		Adds a contains filter for array/range/jsonb columns.

		@param column string -- Column name to filter
		@param value any -- Value that the column should contain
		@return Query -- Returns self for method chaining

		@example
		:contains("tags", {"urgent", "important"}) -- Array contains both values
	]]
    function Query:contains(column: string, value: any)
        return self:filter(column, "cs", value)
    end

    --[[
		Adds a contained by filter for array/range/jsonb columns.

		@param column string -- Column name to filter
		@param value any -- Value that should contain the column
		@return Query -- Returns self for method chaining

		@example
		:containedBy("tags", {"urgent", "important", "critical"}) -- Array is subset of these values
	]]
    function Query:containedBy(column: string, value: any)
        return self:filter(column, "cd", value)
    end

    --[[
		Adds a range strictly right of filter.

		@param column string -- Column name to filter (must be a range type)
		@param range string -- Range value to compare against
		@return Query -- Returns self for method chaining

		@example
		:rangeGt("availability", "[2023-01-01,2023-12-31]")
	]]
    function Query:rangeGt(column: string, range: string)
        return self:filter(column, "sr", range)
    end

    --[[:
		Adds a range does not extend left of filter.

		@param column string -- Column name to filter (must be a range type)
		@param range string -- Range value to compare against
		@return Query -- Returns self for method chaining

		@example
		:rangeGte("availability", "[2023-01-01,2023-12-31]")
	]]
    function Query:rangeGte(column: string, range: string)
        return self:filter(column, "nxl", range)
    end

    --[[
		Adds a range strictly left of filter.

		@param column string -- Column name to filter (must be a range type)
		@param range string -- Range value to compare against
		@return Query -- Returns self for method chaining

		@example
		:rangeLt("availability", "[2023-01-01,2023-12-31]")
	]]
    function Query:rangeLt(column: string, range: string)
        return self:filter(column, "sl", range)
    end

    --[[
		Adds a range does not extend right of filter.

		@param column string -- Column name to filter (must be a range type)
		@param range string -- Range value to compare against
		@return Query -- Returns self for method chaining

		@example
		:rangeLte("availability", "[2023-01-01,2023-12-31]")
	]]
    function Query:rangeLte(column: string, range: string)
        return self:filter(column, "nxr", range)
    end

    --[[
		Adds a range adjacent to filter.

		@param column string -- Column name to filter (must be a range type)
		@param range string -- Range value to compare against
		@return Query -- Returns self for method chaining

		@example
		:rangeAdjacent("availability", "[2023-01-01,2023-12-31]")
	]]
    function Query:rangeAdjacent(column: string, range: string)
        return self:filter(column, "adj", range)
    end

    --[[
		Adds a range overlaps filter.

		@param column string -- Column name to filter (must be a range type)
		@param value any -- Range value to compare against
		@return Query -- Returns self for method chaining

		@example
		:overlaps("availability", "[2023-06-01,2023-08-31]")
	]]
    function Query:overlaps(column: string, value: any)
        return self:filter(column, "ov", value)
    end

    --[[
		Adds multiple equality filters at once.

		@param query {[string]: any} -- Table of column-value pairs for equality filters
		@return Query -- Returns self for method chaining

		@example
		:match({
			status = "active",
			department = "engineering"
		})
	]]
    function Query:match(query: {[string]: any})
        for column, value in pairs(query) do
            self:eq(column, value)
        end
        return self
    end

    --[[
		Adds a negated filter.

		@param column string -- Column name to filter
		@param operator string -- Operator to negate (e.g., "eq", "gt", "like")
		@param value any -- Value to compare against
		@return Query -- Returns self for method chaining

		@example
		:not_("status", "eq", "inactive") -- status != "inactive"
		:not_("name", "like", "test%") -- name NOT LIKE "test%"
	]]
    function Query:not_(column: string, operator: string, value: any)
        return self:filter(column, "not." .. operator, value)
    end

    --[[
		Adds a generic filter with custom operator.

		@param column string -- Column name to filter
		@param operator string -- Operator to use (e.g., "eq", "gt", "cs", "ov")
		@param value any -- Value to compare against
		@return Query -- Returns self for method chaining

		@example
		:filter("age", "gte", 18)
		:filter("tags", "cs", {"urgent"})
	]]
    function Query:filter(column: string, operator: string, value: any)
        local key = Http:UrlEncode(tostring(column))
        local val = Http:UrlEncode(tostring(value))
        local filterStr = ("%s=%s.%s"):format(key, operator, val)
        self.query = (not self.query or self.query == "") and ("?" .. filterStr) or (self.query .. "&" .. filterStr)
        return self
    end

    --[[
		Limits the result to a single row.

		@return Query -- Returns self for method chaining

		@example
		:single() -- Limits to 1 result
	]]
    function Query:single()
        if not self.query or self.query == "" then
            self.query = "?limit=1"
        else
            self.query = self.query .. "&limit=1"
        end
        return self
    end

    --[[
		Adds an OR filter with optional foreign table reference.

		@param filters string -- Filter string in PostgREST format
		@param options OrFilterOptions? -- Optional configuration
		@return Query -- Returns self for method chaining

		@example
		:or_("status.eq.active,department.eq.engineering")
		:or_("status.eq.active,status.eq.pending")
	]]
    function Query:or_(filters: string, options: OrFilterOptions)
        local filterStr = "or=(" .. filters .. ")"
        if options and options.foreignTable then
            filterStr = options.foreignTable .. "." .. filterStr
        end

        self.query = (not self.query or self.query == "") and ("?" .. filterStr) or (self.query .. "&" .. filterStr)
        return self
    end

    --[[
		Adds a full-text search filter.

		@param column string -- Column name to search
		@param query string -- Search query text
		@param options TextSearchOptions? -- Optional text search configuration
		@return Query -- Returns self for method chaining

		@example
		:textSearch("description", "quick brown fox", {
			type = "plain",
			config = "english"
		})
	]]
    function Query:textSearch(self, column: string, query: string, options: TextSearchOptions)
        local tsType = (options and options.type) or "plain"
        local config = (options and options.config) and ("(" .. options.config .. ")") or ""
        local key = Http:UrlEncode(tostring(column))
        -- The query part of text search should not be URL encoded according to PostgREST docs
        local filterStr = ("%s=fts%s(%s).%s"):format(key, config, tsType, query)

        self.query = (not self.query or self.query == "") and ("?" .. filterStr) or (self.query .. "&" .. filterStr)

        return self
    end

    --[[
		Builds the HTTP request from the query configuration.

		@return table -- Request table for HttpService
		@private
	]]
    function Query:_buildRequest()
        return {
            Url = self.url .. self.query,
            Method = self.method or "GET",
            Headers = {
                ["apikey"] = self.key,
                ["Authorization"] = "Bearer " .. self.key,
                ["Content-Type"] = "application/json",
            },
        }
    end

    --[[
		Executes the query and returns the results.

		@return any -- Query results (table or nil on error)
		@return string? -- Error message if request failed, nil otherwise

		@example
		local results, err = query:execute()
		if err then
			warn("Error:", err)
		else
			print("Results:", results)
		end
	]]
    function Query:execute()
        local req = self:_buildRequest()
        local res = Http:RequestAsync(req)

        if not res.Success then
            -- Try to decode Supabase error payload to return a clearer message
            local okErr, errObj = pcall(function()
                if res.Body and res.Body ~= "" then
                    return Http:JSONDecode(res.Body)
                end
                return nil
            end)

            if okErr and type(errObj) == "table" then
                local message = errObj.message or errObj.error_description or errObj.error or errObj.hint or errObj.details or res.StatusMessage
                return nil, ("Supabase error: %s"):format(tostring(message))
            end

            return nil, ("HTTP Request failed: %s"):format(tostring(res.StatusMessage))
        end

        local ok, decoded = pcall(function() return Http:JSONDecode(res.Body) end)
        if ok then
            return decoded, nil
        end
        return res.Body, nil
    end

    --[[
		Executes the query and validates results against a runtime schema if available.

		@return any -- Query results (table or nil on error)
		@return string? -- Error message if validation or request failed, nil otherwise

		@example
		local typedResults, err = query:executeTyped()
		if err then
			warn("Type validation error:", err)
		end
	]]
    function Query:executeTyped()
        local rows, err = self:execute()
        if err then
            return nil, err
        end

        local typesModule = self._typesModule or (self.supabase and self.supabase._typesModule)
        if typesModule and typesModule.schemas and typesModule.schemas[self.table] then
            local schema = typesModule.schemas[self.table]
            if type(rows) == "table" then
                for idx, row in ipairs(rows) do
                    if not validateValue(row, schema) then
                        return nil, ("Row %d did not match schema for table '%s'"):format(idx, self.table)
                    end
                end
            else
                -- single object
                if not validateValue(rows, schema) then
                    return nil, ("Result did not match schema for table '%s'"):format(self.table)
                end
            end
        end
        return rows, nil
    end

    local instance = setmetatable({
        url = self.baseUrl .. "/rest/v1/" .. tableName,
        key = self.key,
        query = "",
        table = tableName,
        supabase = self,
        _typesModule = self._typesModule,
    }, Query)

    return instance
end

return Rest