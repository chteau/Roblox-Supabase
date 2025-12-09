--[[
	Filter operators and utilities for building query filters.

	@module Rest.QueryOperators
	@private
]]
local QueryOperators = {}

local Http = game:GetService("HttpService")

-- Re-export types for internal use
local Types = require(script.Parent.Types)
export type OrFilterOptions = Types.OrFilterOptions
export type TextSearchOptions = Types.TextSearchOptions

--[[
	Adds a filter with the specified operator to the query.

	@param self table -- Query instance
	@param column string -- Column name to filter
	@param operator string -- Operator to use
	@param value any -- Value to compare against
	@return table -- Returns self for method chaining
]]
function QueryOperators:filter(column: string, operator: string, value: any)
    local key = Http:UrlEncode(tostring(column))
    local val = Http:UrlEncode(tostring(value))
    local filterStr = ("%s=%s.%s"):format(key, operator, val)
    self.query = (not self.query or self.query == "") and ("?" .. filterStr) or (self.query .. "&" .. filterStr)
    return self
end

--[[
	Adds an IN list filter to match against multiple values.

	@param self table -- Query instance
	@param column string -- Column name to filter
	@param values {any} -- Array of values to match against
	@return table -- Returns self for method chaining
]]
function QueryOperators:in_(column: string, values: {any})
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
	Adds an OR filter with optional foreign table reference.

	@param self table -- Query instance
	@param filters string -- Filter string in PostgREST format
	@param options OrFilterOptions? -- Optional configuration
	@return table -- Returns self for method chaining
]]
function QueryOperators:or_(filters: string, options: OrFilterOptions)
    local filterStr = "or=(" .. filters .. ")"
    if options and options.foreignTable then
        filterStr = options.foreignTable .. "." .. filterStr
    end

    self.query = (not self.query or self.query == "") and ("?" .. filterStr) or (self.query .. "&" .. filterStr)
    return self
end

--[[
	Adds multiple equality filters at once.

	@param self table -- Query instance
	@param query {[string]: any} -- Table of column-value pairs for equality filters
	@return table -- Returns self for method chaining
]]
function QueryOperators:match(query: {[string]: any})
    for column, value in pairs(query) do
        self:eq(column, value)
    end
    return self
end

return QueryOperators