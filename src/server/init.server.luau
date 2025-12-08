local Supabase = require(script.Supabase.Client)

print("Server tests")

local Client = Supabase.createClient({
    url = "https://rrvscifslutlpnbtqedf.supabase.co",
    apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJydnNjaWZzbHV0bHBuYnRxZWRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzYxMTA1NDgsImV4cCI6MjA1MTY4NjU0OH0.fBpclIS3qVlGmNGwld75_9qOuJvks5hPuQVdqwOXCBg"
})

print("Client created", Client)
print("Table fetch test")

local _, Error = Client
    :from("Scripts")
    :select("id, poop")
    :eq("id", 2)
    :execute()

print("Result:", _, Error)