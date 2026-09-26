-- check-workspace.luau
-- Verifies game:GetService("Workspace") is raw-equal to game.Workspace.

local Workspace = game:GetService("Workspace")

assert(rawequal(Workspace, game.Workspace), "[3] Service mismatch")

print("hooray")
