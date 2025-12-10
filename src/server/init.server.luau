--[[
    Example usage of the Supabase modulescript in your Roblox Project.
    @author Cheeteau
--]]
local Supabase = require(game:GetService("ServerStorage"):WaitForChild("Supabase"))

local client = Supabase.createClient({
    url = "https://rrvscifslutlpnbtqedf.supabase.co",
    apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJydnNjaWZzbHV0bHBuYnRxZWRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzYxMTA1NDgsImV4cCI6MjA1MTY4NjU0OH0.fBpclIS3qVlGmNGwld75_9qOuJvks5hPuQVdqwOXCBg"
})

-- Update a player and return all updated columns
local updatedPlayer, error = client
    :from("players")
    :update({
        level = 15,
        experience = 10000,
        last_login = os.date("!%Y-%m-%d %H:%M:%S")
    })
    :eq("id", 8)
    :select()
    :execute()

if error then
    warn("Failed to update player:", error)
else
    print("Player updated. New level:", updatedPlayer)
end