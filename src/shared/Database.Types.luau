--[[
Example Database.Types module
Users can replace or extend this file. It provides both Luau type exports
and a runtime `schemas` table used for lightweight validation.
]]

export type User = {
    id: number,
    email: string,
    is_verified: boolean,
}

export type Profile = {
    id: number,
    user_id: number,
    display_name: string,
}

local schemas = {
    users = {
        id = "number",
        email = "string",
        is_verified = "boolean",
    },
    profiles = {
        id = "number",
        user_id = "number",
        display_name = "string",
    },
}

return {
    schemas = schemas,
}
