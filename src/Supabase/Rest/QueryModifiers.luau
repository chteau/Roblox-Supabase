--[[
	Query modifiers for ordering, limiting, and other query operations.

	@module Rest.QueryModifiers
	@private
]]
local QueryModifiers = {}

local Http = game:GetService("HttpService")

-- Re-export types for internal use
local Types = require(script.Parent.Types)
export type OrderOptions = Types.OrderOptions
export type LimitOptions = Types.LimitOptions
export type RangeOptions = Types.RangeOptions
export type ExplainOptions = Types.ExplainOptions

--[[
	Adds an ORDER BY clause to the query.

	@param column string -- Column to order by
	@param options OrderOptions? -- Ordering options
	@return table -- Returns self for method chaining

	@example
	:order("created_at", { ascending = false })
	:order("name", { ascending = true, nullsFirst = true })
	:order("users(name)", { foreignTable = "profiles" })
]]
function QueryModifiers:order(column: string, options: OrderOptions)
    local orderStr = Http:UrlEncode(tostring(column))

    if options then
        if options.ascending ~= nil then
            orderStr = orderStr .. (options.ascending and ".asc" or ".desc")
        end

        if options.nullsFirst ~= nil then
            orderStr = orderStr .. (options.nullsFirst and ".nullsfirst" or ".nullslast")
        end

        if options.foreignTable then
            orderStr = options.foreignTable .. "." .. orderStr
        elseif options.referencedTable then
            orderStr = orderStr .. "(" .. options.referencedTable .. "(*))"
        end
    end

    local paramName = "order"
    if options and options.foreignTable then
        paramName = options.foreignTable .. ".order"
    end

    if not self.query or self.query == "" then
        self.query = "?" .. paramName .. "=" .. orderStr
    else
        self.query = self.query .. "&" .. paramName .. "=" .. orderStr
    end

    return self
end

--[[
	Limits the number of rows returned.

	@param count number -- Maximum number of rows to return
	@param options LimitOptions? -- Limit options
	@return table -- Returns self for method chaining

	@example
	:limit(10)
	:limit(5, { foreignTable = "comments" })
]]
function QueryModifiers:limit(count: number, options: LimitOptions)
    local paramName = "limit"
    if options and options.foreignTable then
        paramName = options.foreignTable .. ".limit"
    elseif options and options.referencedTable then
        paramName = "limit"
    end

    if not self.query or self.query == "" then
        self.query = "?" .. paramName .. "=" .. tostring(count)
    else
        self.query = self.query .. "&" .. paramName .. "=" .. tostring(count)
    end

    return self
end

--[[
	Limits the query to a specific range of rows (pagination).

	@param from number -- Starting index (inclusive, 0-based)
	@param to number -- Ending index (inclusive)
	@param options RangeOptions? -- Range options
	@return table -- Returns self for method chaining

	@example
	:range(0, 9) -- First 10 rows
	:range(10, 19) -- Next 10 rows
]]
function QueryModifiers:range(from: number, to: number, options: RangeOptions)
    local rangeStr = tostring(from) .. "-" .. tostring(to)

    -- Store range for use in request headers
    if not self.ranges then
        self.ranges = {}
    end

    local key = "range"
    if options and options.foreignTable then
        key = options.foreignTable .. ".range"
    end

    table.insert(self.ranges, {
        key = key,
        value = rangeStr,
        options = options
    })

    return self
end

--[[
	Limits the result to one row and returns as a single object.
	Sets the Accept header to expect a single object.

	@return table -- Returns self for method chaining

	@example
	:single()
]]
function QueryModifiers:single()
    -- Add limit=1 to the query
    if not self.query or self.query == "" then
        self.query = "?limit=1"
    else
        self.query = self.query .. "&limit=1"
    end

    -- Mark that we expect a single object
    self._expectSingle = true
    self._singleMode = "single"

    return self
end

--[[
	Limits the result to one row, returns as a single object or null if not found.

	@return table -- Returns self for method chaining

	@example
	:maybeSingle()
]]
function QueryModifiers:maybeSingle()
    -- Add limit=1 to the query
    if not self.query or self.query == "" then
        self.query = "?limit=1"
    else
        self.query = self.query .. "&limit=1"
    end

    -- Mark that we expect a single object but can return null
    self._expectSingle = true
    self._singleMode = "maybeSingle"

    return self
end

--[[
	Requests the response in CSV format.

	@return table -- Returns self for method chaining

	@example
	:csv()
]]
function QueryModifiers:csv()
    -- Mark that we want CSV format
    self._responseFormat = "csv"
    return self
end

--[[
	Sets the return representation preference.

	@param representation "minimal" | "representation" -- Return preference
	@return table -- Returns self for method chaining

	@example
	:returns("minimal") -- Returns only status, no body
	:returns("representation") -- Returns full resource representation
]]
function QueryModifiers:returns(representation: "minimal" | "representation")
    if representation ~= "minimal" and representation ~= "representation" then
        error("returns() expects either 'minimal' or 'representation'")
    end

    self._returns = representation
    return self
end

--[[
	Overrides the type schema for this specific query.

	@param schema table -- Schema definition to use for validation
	@return table -- Returns self for method chaining

	@example
	:overrideTypes({
		id = "string",
		name = "string",
		age = "number"
	})
]]
function QueryModifiers:overrideTypes(schema: table)
    self._overrideSchema = schema
    return self
end

--[[
	Requests the query execution plan instead of actual results.

	@param options ExplainOptions? -- Explain options
	@return table -- Returns self for method chaining

	@example
	:explain()
	:explain({ analyze = true, format = "json" })
]]
function QueryModifiers:explain(options: ExplainOptions)
    local params = {}

    if options then
        if options.analyze then table.insert(params, "analyze") end
        if options.verbose then table.insert(params, "verbose") end
        if options.settings then table.insert(params, "settings") end
        if options.buffers then table.insert(params, "buffers") end
        if options.wal then table.insert(params, "wal") end
        if options.format then
            table.insert(params, "format " .. options.format)
        end
    end

    self._explain = table.concat(params, ",")
    return self
end

return QueryModifiers