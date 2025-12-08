local Http = game:GetService("HttpService")

local Functions = {}
Functions.__index = Functions

export type FunctionsClient = {
    invoke: (self: FunctionsClient, functionName: string, payload: table?) -> any,
}

function Functions.new(baseUrl: string, key: string): FunctionsClient
    local self = setmetatable({}, Functions)

    self.baseUrl = baseUrl .. "/functions/v1"
    self.key = key

    return (self :: any) :: FunctionsClient
end

function Functions:invoke(functionName: string, payload: table?): any
    local body = if payload then Http:JSONEncode(payload) else nil

    local res = Http:RequestAsync({
        Url = self.baseUrl .. "/" .. functionName,
        Method = "POST",
        Headers = {
            ["apikey"] = self.key,
            ["Authorization"] = "Bearer " .. self.key,
            ["Content-Type"] = "application/json",
        },
        Body = body,
    })

    if not res.Success then
        error("HTTP Request failed: " .. res.StatusMessage)
    end

    return Http:JSONDecode(res.Body)
end

return Functions