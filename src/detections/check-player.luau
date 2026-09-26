-- check-player.luau
-- GetPlayerByUserId only resolves players in the current experience; user
-- ID 1 (Roblox) can never be here, so it must return nil.

local Players = game:GetService("Players")

local player = Players:GetPlayerByUserId(1)
assert(player == nil, "dtc")

print("hooray")