local Http = game:GetService("HttpService")

local Storage = {}
Storage.__index = Storage

export type StorageClient = {
    upload: (self: StorageClient, bucket: string, path: string, fileData: string) -> any,
}

function Storage.new(baseUrl: string, key: string): StorageClient
    local self = setmetatable({}, Storage)

    self.baseUrl = baseUrl .. "/storage/v1"
    self.key = key

    return (self :: any) :: StorageClient
end

function Storage:upload(bucket: string, path: string, fileData: string): any
    local res = Http:RequestAsync({
        Url = self.baseUrl .. "/object/" .. bucket .. "/" .. path,
        Method = "POST",
        Headers = {
            ["apikey"] = self.key,
            ["Authorization"] = "Bearer " .. self.key,
            ["Content-Type"] = "application/octet-stream",
        },
        Body = fileData,
    })

    if not res.Success then
        error("HTTP Request failed: " .. res.StatusMessage)
    end

    return Http:JSONDecode(res.Body)
end

return Storage