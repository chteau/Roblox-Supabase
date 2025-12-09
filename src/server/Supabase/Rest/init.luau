--[[
	The main REST client class for interacting with Supabase PostgREST API.

	@module Rest
	@client
]]
local Rest = {}
Rest.__index = Rest

-- Import dependencies
local Utils = require(script.Utils)
local Types = require(script.Types)
local QueryBuilder = require(script.QueryBuilder)

-- Re-export types
export type OrFilterOptions = Types.OrFilterOptions
export type TextSearchOptions = Types.TextSearchOptions
export type InsertOptions = Types.InsertOptions
export type UpdateOptions = Types.UpdateOptions
export type DeleteOptions = Types.DeleteOptions
export type OrderOptions = Types.OrderOptions
export type LimitOptions = Types.LimitOptions
export type RangeOptions = Types.RangeOptions
export type ExplainOptions = Types.ExplainOptions
export type RootQuery = Types.RootQuery
export type SelectQuery = Types.SelectQuery
export type InsertQuery = Types.InsertQuery
export type UpdateQuery = Types.UpdateQuery
export type DeleteQuery = Types.DeleteQuery
export type UpsertQuery = Types.UpsertQuery
export type RestClient = Types.RestClient

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
    self._typesModule = Utils.tryLoadTypes(script)

    return (self :: any) :: RestClient
end

--[[
	Creates a query builder for a specific table.

	@param tableName string -- The name of the table to query
	@return RootQuery -- A query builder instance for the specified table

	@example
	local query = supabase:from("users")
		:select("*")
		:eq("status", "active")
		:execute()
]]
function Rest:from(tableName: string): RootQuery
    return QueryBuilder.new(self.baseUrl, self.key, tableName, self._typesModule)
end

return Rest