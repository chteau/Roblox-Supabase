--[[
	The main Supabase Edge Functions client for invoking serverless functions.
]]
local Http = game:GetService("HttpService")

local Functions = {}
Functions.__index = Functions

export type FunctionsInvokeOptions = {
    headers: table?,
    method: "POST" | "GET" | "PUT" | "DELETE" | "PATCH",
    region: string?,
}

export type FunctionsClient = {
    invoke: (self: FunctionsClient, functionName: string, payload: table?, options: FunctionsInvokeOptions?) -> (any, string?),
    invokeRaw: (self: FunctionsClient, functionName: string, payload: table?, options: FunctionsInvokeOptions?) -> (table, string?),
}

function Functions.new(baseUrl: string, key: string): FunctionsClient
    local self = setmetatable({}, Functions)

    self.baseUrl = baseUrl .. "/functions/v1"
    self.key = key

    return (self :: any) :: FunctionsClient
end

--[[
    Invokes a Supabase Edge Function and returns the parsed JSON response.

    @param functionName string -- Name of the Edge Function to invoke
    @param payload table? -- Optional payload to send to the function
    @param options FunctionsInvokeOptions? -- Optional invoke options
    @return any -- Parsed JSON response
    @return string? -- Error message if any
]]
function Functions:invoke(functionName: string, payload: table?, options: FunctionsInvokeOptions?): (any, string?)
    local body = if payload then Http:JSONEncode(payload) else nil

    local params = ""
    local headers = {
        ["apikey"] = self.key,
        ["Authorization"] = "Bearer " .. self.key,
        ["Content-Type"] = "application/json",
    }

    if options then
        if options.region then
            headers["x-region"] = options.region
            params = "?forceFunctionRegion=" .. options.region
        end

        if options.headers then
            for k, v in pairs(options.headers) do
                headers[k] = v
            end
        end
    end

    local res = Http:RequestAsync({
        Url = self.baseUrl .. "/" .. functionName .. params,
        Method = options.method or "POST",
        Headers = headers,
        Body = body,
    })

    if not res.Success then
        -- Try to parse error response
        local errorMessage = res.StatusMessage
        if res.Body and res.Body ~= "" then
            local ok, errData = pcall(function()
                return Http:JSONDecode(res.Body)
            end)
            if ok and errData and errData.message then
                errorMessage = errData.message
            elseif ok and errData and errData.error then
                errorMessage = errData.error
            end
        end
        return nil, ("Edge Function '%s' failed: %s"):format(functionName, errorMessage)
    end

    -- Handle empty response
    if res.Body == nil or res.Body == "" then
        return nil, nil
    end

    -- Check content type for parsing
    local contentType = res.Headers["Content-Type"] or res.Headers["content-type"]

    -- Plain text response
    if contentType and string.find(contentType, "text/") then
        return res.Body, nil
    end

    -- JSON response
    if contentType and string.find(contentType, "application/json") then
        local ok, decoded = pcall(function()
            return Http:JSONDecode(res.Body)
        end)

        if not ok then
            return nil, "Failed to parse Edge Function response as JSON"
        end

        return decoded, nil
    end

    -- Fallback
    local ok, decoded = pcall(function()
        return Http:JSONDecode(res.Body)
    end)

    --

    if not ok then
        return nil, "Failed to parse Edge Function response as JSON"
    end

    return decoded, nil
end

--[[
    Invokes a Supabase Edge Function and returns the raw HTTP response.

    @param functionName string -- Name of the Edge Function to invoke
    @param payload table? -- Optional payload to send to the function
    @param options FunctionsInvokeOptions? -- Optional invoke options
    @return table -- Raw HTTP response table
    @return string? -- Error message if any
]]
function Functions:invokeRaw(functionName: string, payload: table?, options: FunctionsInvokeOptions?): (table, string?)
    local body = if payload then Http:JSONEncode(payload) else nil

    local params = ""
    local headers = {
        ["apikey"] = self.key,
        ["Authorization"] = "Bearer " .. self.key,
        ["Content-Type"] = "application/json",
    }

    if options then
        if options.region then
            headers["x-region"] = options.region
            params = "?forceFunctionRegion=" .. options.region
        end

        if options.headers then
            for k, v in pairs(options.headers) do
                headers[k] = v
            end
        end
    end

    local res = Http:RequestAsync({
        Url = self.baseUrl .. "/" .. functionName .. params,
        Method = options.method or "POST",
        Headers = headers,
        Body = body,
    })

    if not res.Success then
        return nil, ("Edge Function '%s' failed: %s"):format(functionName, res.StatusMessage)
    end

    return res, nil
end

return Functions