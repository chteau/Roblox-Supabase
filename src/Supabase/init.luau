--[[
	Main Supabase client module that provides unified access to all Supabase services.

	This module serves as the primary entry point for the Supabase client, providing:
	- Database queries via PostgREST (select, insert, update, delete, upsert)
	- PostgreSQL function calls (RPC)
	- File storage operations
	- Edge Functions invocation
	- Comprehensive unit testing capabilities

	The client is designed for server-side use only to prevent API key exposure.

	@module Supabase
	@see Rest
	@see Storage
	@see EdgeFunctions
	@see UnitTests
]]

local Rest = require(script.Rest)
local Storage = require(script.Storage)
local EdgeFunctions = require(script.EdgeFunctions)
local UnitTests = require(script.UnitTests)
local RunService = game:GetService("RunService")

local Supabase = {}
Supabase.__index = Supabase

-- Import types from Rest module for type safety and autocomplete
local RestTypes = require(script.Rest.Types)
export type RootQuery = RestTypes.RootQuery
export type RPCFilterStage = RestTypes.RPCFilterStage

--[[
	Supabase client type definition.

	@type SupabaseClient
	@within Supabase
	@property rest Rest.RestClient -- REST API client for database operations
	@property storage Storage.StorageClient -- Storage client for file operations
	@property functions EdgeFunctions.FunctionsClient -- Edge Functions client
	@property _unitTests UnitTests.UnitTests -- Internal unit testing module

	@method from (tableName: string) -> RootQuery -- Creates a query builder for the specified table
	@method rpc (functionName: string, params: {[string]: any}?) -> RPCFilterStage -- Calls a PostgreSQL function
]]
export type SupabaseClient = {
	rest: Rest.RestClient,
	storage: any, -- Storage.StorageClient (typed internally)
	functions: EdgeFunctions.FunctionsClient,
	_unitTests: UnitTests.UnitTests,

	from: (self: SupabaseClient, tableName: string) -> RootQuery,
	rpc: (self: SupabaseClient, functionName: string, params: {[string]: any}?) -> RPCFilterStage,
}

--[[
	Creates a new Supabase client instance.

	This constructor initializes all service clients (REST, Storage, Edge Functions)
	and sets up the necessary configuration. It also includes safety checks to
	ensure the client is only used on the server side to prevent API key leakage.

	@param baseUrl string -- The base URL of your Supabase project (e.g., "https://your-project.supabase.co")
	@param key string -- Your Supabase API key (anon or service role key)
	@return SupabaseClient -- A new Supabase client instance

	@error "Supabase client must be created on the server" if called from client-side code
]]
function Supabase.new(baseUrl: string, key: string): SupabaseClient
	local self = setmetatable({}, Supabase)

	-- Ensure this client is only created on the server to avoid leaking keys.
	if not RunService:IsServer() then
		error("Supabase client must be created on the server (server-side only). Do NOT use on client-side code.")
	end

	self.url = baseUrl
	self.key = key

	-- Initialize service clients
	self.rest = Rest.new(baseUrl, key)
	self.storage = Storage.new(baseUrl, key)
	self.functions = EdgeFunctions.new(baseUrl, key)

	--[[
		Proxy method for table queries.

		Provides a convenient interface for building database queries against a specific table.
		This method follows the chainable pattern: client:from("table"):select("*"):execute()

		@param tableName string -- Name of the database table to query
		@return RootQuery -- A query builder instance for the specified table
	]]
	function self:from(tableName: string): RootQuery
		return self.rest:from(tableName)
	end

	--[[
		Proxy method for PostgreSQL function calls (RPC).

		Allows calling PostgreSQL functions with optional parameters. Functions can return
		scalar values, JSON objects, or table sets that can be further filtered.

		@param functionName string -- Name of the PostgreSQL function to call
		@param params {[string]: any}? -- Optional parameters to pass to the function
		@return RPCQuery -- An RPC query builder instance

		@example
		-- Call a function with parameters
		client:rpc("calculate_total", { price = 99.99, quantity = 3 }):execute()

		-- Call a function that returns a table and apply filters
		client:rpc("get_active_users"):eq("status", "active"):limit(10):execute()
	]]
	function self:rpc(functionName: string, params: {[string]: any}?): RootQuery
		return self.rest:rpc(functionName, params)
	end

	-- Internal unit testing module for comprehensive validation
	self._unitTests = UnitTests.new(self)

	return (self :: any) :: SupabaseClient
end

--[[
	Type-safe factory method for creating a Supabase client.

	This method provides a more idiomatic configuration interface similar to the
	TypeScript Supabase client. It validates configuration parameters and ensures
	server-side execution before delegating to the main constructor.

	@param config { url: string, apiKey: string } -- Configuration table
	@param config.url string -- The base URL of your Supabase project
	@param config.apiKey string -- Your Supabase API key
	@return SupabaseClient -- A new Supabase client instance

	@error "createClient expects a config table" if config is not a table
	@error "config.url must be a string" if url is invalid
	@error "config.apiKey must be a string" if apiKey is invalid
	@error "Supabase.createClient must be called from server-side code" if called from client

	@example
	local client = Supabase.createClient({
		url = "https://your-project.supabase.co",
		apiKey = "your-anon-or-service-role-key",
	})
]]
function Supabase.createClient(config: { url: string, apiKey: string }): SupabaseClient
	assert(type(config) == "table", "createClient expects a config table")
	assert(type(config.url) == "string", "config.url must be a string")
	assert(type(config.apiKey) == "string", "config.apiKey must be a string")
	if not RunService:IsServer() then
		error("Supabase.createClient must be called from server-side code. Do NOT call from client scripts.")
	end

	return Supabase.new(config.url, config.apiKey)
end

return Supabase