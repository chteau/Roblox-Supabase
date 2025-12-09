--[[
	Mutation methods for inserting, updating, and deleting data.

	@module Rest.QueryMutations
	@private
]]
local QueryMutations = {}

local Http = game:GetService("HttpService")

-- Re-export types for internal use
local Types = require(script.Parent.Types)
export type InsertOptions = Types.InsertOptions
export type UpdateOptions = Types.UpdateOptions
export type DeleteOptions = Types.DeleteOptions

--[[
	Inserts one or more rows into the table.
	Returns an InsertQuery type that only allows return modifiers.

	@param data table | {table} -- Single row or array of rows to insert
	@param options InsertOptions? -- Insert options
	@return InsertQuery -- Returns insert-specific query
]]
function QueryMutations:insert(data: table | {table}, options: InsertOptions)
    self.method = "POST"
    self.body = data
    self._insertOptions = options

    -- Set default returning behavior if not specified
    if not options or options.returning == nil then
        self._insertOptions = self._insertOptions or {}
        self._insertOptions.returning = "representation"
    end

    -- Change the metatable to InsertQuery to restrict available methods
    return setmetatable(self, getmetatable(self) --[[@as InsertQuery]])
end

--[[
	Updates rows in the table.
	Returns a FilterableQuery that allows filters.

	@param data table -- Data to update
	@param options UpdateOptions? -- Update options
	@return FilterableQuery -- Returns filterable query
]]
function QueryMutations:update(data: table, options: UpdateOptions)
    self.method = "PATCH"
    self.body = data
    self._updateOptions = options

    -- Set default returning behavior if not specified
    if not options or options.returning == nil then
        self._updateOptions = self._updateOptions or {}
        self._updateOptions.returning = "representation"
    end

    -- Keep the same metatable (FilterableQuery)
    return self
end

--[[
	Deletes rows from the table.
	Returns a FilterableQuery that allows filters.

	@param options DeleteOptions? -- Delete options
	@return FilterableQuery -- Returns filterable query
]]
function QueryMutations:delete(options: DeleteOptions)
    self.method = "DELETE"
    self._deleteOptions = options

    -- Set default returning behavior if not specified
    if not options or options.returning == nil then
        self._deleteOptions = self._deleteOptions or {}
        self._deleteOptions.returning = "representation"
    end

    -- Keep the same metatable (FilterableQuery)
    return self
end

--[[
	Upserts one or more rows (insert or update on conflict).
	Returns an UpsertQuery type that only allows return modifiers.

	@param data table | {table} -- Single row or array of rows to upsert
	@param options InsertOptions? -- Upsert options
	@return UpsertQuery -- Returns upsert-specific query
]]
function QueryMutations:upsert(data: table | {table}, options: InsertOptions)
    self.method = "POST"
    self.body = data

    -- Ensure upsert option is set
    self._insertOptions = options or {}
    self._insertOptions.upsert = true

    -- Set default returning behavior if not specified
    if not options or options.returning == nil then
        self._insertOptions.returning = "representation"
    end

    -- Change the metatable to UpsertQuery to restrict available methods
    return setmetatable(self, getmetatable(self) --[[@as UpsertQuery]])
end

return QueryMutations