--[[
	Filter methods for building database queries.

	@module Rest.QueryFilters
	@private
]]
local QueryFilters = {}
local Http = game:GetService("HttpService")

--[[
	Adds an equality filter (equals).

	@param column string -- Column name to filter
	@param value any -- Value to compare against
	@return table -- Returns self for method chaining
]]
function QueryFilters:eq(column: string, value: any)
    return self:filter(column, "eq", value)
end

--[[
	Adds an inequality filter (not equals).

	@param column string -- Column name to filter
	@param value any -- Value to compare against
	@return table -- Returns self for method chaining
]]
function QueryFilters:neq(column: string, value: any)
    return self:filter(column, "neq", value)
end

--[[
	Adds a greater than filter.

	@param column string -- Column name to filter
	@param value any -- Value to compare against
	@return table -- Returns self for method chaining
]]
function QueryFilters:gt(column: string, value: any)
    return self:filter(column, "gt", value)
end

--[[
	Adds a greater than or equal filter.

	@param column string -- Column name to filter
	@param value any -- Value to compare against
	@return table -- Returns self for method chaining
]]
function QueryFilters:gte(column: string, value: any)
    return self:filter(column, "gte", value)
end

--[[
	Adds a less than filter.

	@param column string -- Column name to filter
	@param value any -- Value to compare against
	@return table -- Returns self for method chaining
]]
function QueryFilters:lt(column: string, value: any)
    return self:filter(column, "lt", value)
end

--[[
	Adds a less than or equal filter.

	@param column string -- Column name to filter
	@param value any -- Value to compare against
	@return table -- Returns self for method chaining
]]
function QueryFilters:lte(column: string, value: any)
    return self:filter(column, "lte", value)
end

--[[
	Adds a LIKE pattern match filter (case-sensitive).

	@param column string -- Column name to filter
	@param pattern string -- SQL LIKE pattern (use % as wildcard)
	@return table -- Returns self for method chaining
]]
function QueryFilters:like(column: string, pattern: string)
    return self:filter(column, "like", pattern)
end

--[[
	Adds a case-insensitive LIKE pattern match filter.

	@param column string -- Column name to filter
	@param pattern string -- SQL LIKE pattern (use % as wildcard)
	@return table -- Returns self for method chaining
]]
function QueryFilters:ilike(column: string, pattern: string)
    return self:filter(column, "ilike", pattern)
end

--[[
	Adds an IS NULL or IS TRUE/FALSE filter.

	@param column string -- Column name to filter
	@param value boolean | "null" -- Value to compare against (true, false, or "null")
	@return table -- Returns self for method chaining
]]
function QueryFilters:is(column: string, value: boolean | "null")
    return self:filter(column, "is", value)
end

--[[
	Adds a contains filter for array/range/jsonb columns.

	@param column string -- Column name to filter
	@param value any -- Value that the column should contain
	@return table -- Returns self for method chaining
]]
function QueryFilters:contains(column: string, value: any)
    -- If the value is a dictionary or an array, handle it
    if typeof(value) == "table" then
        -- Check if the table is an array or dictionary
        local isArray = true
        for k, _ in pairs(value) do
            if typeof(k) ~= "number" then
                isArray = false
                break
            end
        end

        if isArray then
            local arrayStr = "{" .. table.concat(value, ",") .. "}"
            return self:filter(column, "cs", arrayStr)
        else
            return self:filter(column, "cs", Http:JSONEncode(value))
        end
    end

    -- If the value is a string, use it directly
    if typeof(value) == "string" then
        return self:filter(column, "cs", value)
    end

    -- For other types, json stringify the value
    return self:filter(column, "cs", Http:JSONEncode(value))
end

--[[
	Adds a contained by filter for array/range/jsonb columns.

	@param column string -- Column name to filter
	@param value any -- Value that should contain the column
	@return table -- Returns self for method chaining
]]
function QueryFilters:containedBy(column: string, value: any)
    -- If the value is a dictionary or an array, handle it
    if typeof(value) == "table" then
        -- Check if the table is an array or dictionary
        local isArray = true
        for k, _ in pairs(value) do
            if typeof(k) ~= "number" then
                isArray = false
                break
            end
        end

        if isArray then
            local arrayStr = "{" .. table.concat(value, ",") .. "}"
            return self:filter(column, "cd", arrayStr)
        else
            return self:filter(column, "cd", Http:JSONEncode(value))
        end
    end

    -- If the value is a string, use it directly
    if typeof(value) == "string" then
        return self:filter(column, "cd", value)
    end

    -- For other types, json stringify the value
    return self:filter(column, "cd", Http:JSONEncode(value))
end

--[[
	Adds a range strictly right of filter.

	@param column string -- Column name to filter (must be a range type)
	@param range string -- Range value to compare against
	@return table -- Returns self for method chaining
]]
function QueryFilters:rangeGt(column: string, range: string)
    return self:filter(column, "sr", range)
end

--[[
	Adds a range does not extend left of filter.

	@param column string -- Column name to filter (must be a range type)
	@param range string -- Range value to compare against
	@return table -- Returns self for method chaining
]]
function QueryFilters:rangeGte(column: string, range: string)
    return self:filter(column, "nxl", range)
end

--[[
	Adds a range strictly left of filter.

	@param column string -- Column name to filter (must be a range type)
	@param range string -- Range value to compare against
	@return table -- Returns self for method chaining
]]
function QueryFilters:rangeLt(column: string, range: string)
    return self:filter(column, "sl", range)
end

--[[
	Adds a range does not extend right of filter.

	@param column string -- Column name to filter (must be a range type)
	@param range string -- Range value to compare against
	@return table -- Returns self for method chaining
]]
function QueryFilters:rangeLte(column: string, range: string)
    return self:filter(column, "nxr", range)
end

--[[
	Adds a range adjacent to filter.

	@param column string -- Column name to filter (must be a range type)
	@param range string -- Range value to compare against
	@return table -- Returns self for method chaining
]]
function QueryFilters:rangeAdjacent(column: string, range: string)
    return self:filter(column, "adj", range)
end

--[[
	Adds a range overlaps filter.

	@param column string -- Column name to filter (must be a range type)
	@param value any -- Range value to compare against
	@return table -- Returns self for method chaining
]]
function QueryFilters:overlaps(column: string, value: any)
    return self:filter(column, "ov", value)
end

--[[
	Adds a negated filter.

	@param column string -- Column name to filter
	@param operator string -- Operator to negate (e.g., "eq", "gt", "like")
	@param value any -- Value to compare against
	@return table -- Returns self for method chaining
]]
function QueryFilters:not_(column: string, operator: string, value: any)
    return self:filter(column, "not." .. operator, value)
end

return QueryFilters