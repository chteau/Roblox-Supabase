local Rest = require(script.Rest)
local Storage = require(script.Storage)
local EdgeFunctions = require(script.EdgeFunctions)
local UnitTests = require(script.UnitTests)
local RunService = game:GetService("RunService")

local Supabase = {}
Supabase.__index = Supabase

-- Import types from Rest module
local RestTypes = require(script.Rest.Types)
export type RootQuery = RestTypes.RootQuery
export type RPCQeuery = RestTypes.RPCQuery

export type SupabaseClient = {
    rest: Rest.RestClient,
    storage: any, -- Storage.StorageClient
    functions: EdgeFunctions.FunctionsClient,
    _unitTests: UnitTests.UnitTests,

    from: (self: SupabaseClient, tableName: string) -> RootQuery,
    rpc: (self: SupabaseClient, functionName: string, params: {[string]: any}?) -> RPCQeuery,
}

-- Backwards-compatible constructor
function Supabase.new(baseUrl: string, key: string): SupabaseClient
    local self = setmetatable({}, Supabase)

    -- Ensure this client is only created on the server to avoid leaking keys.
    if not RunService:IsServer() then
        error("Supabase client must be created on the server (server-side only). Do NOT use on client-side code.")
    end

    self.url = baseUrl
    self.key = key

    self.rest = Rest.new(baseUrl, key)
    self.storage = Storage.new(baseUrl, key)
    self.functions = EdgeFunctions.new(baseUrl, key)

    -- Proxy convenience so callers can do: client:from("table"):select("*"):execute()
    function self:from(tableName: string): RootQuery
        return self.rest:from(tableName)
    end

    -- Proxy convenience for RPC calls
    function self:rpc(functionName: string, params: {[string]: any}?): RootQuery
        return self.rest:rpc(functionName, params)
    end

    -- Addtional unit tests module
    self._unitTests = UnitTests.new(self)

    return (self :: any) :: SupabaseClient
end

-- TypeScript-like factory using a config table
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