-- check-localplayer.luau
-- The first player in Players:GetPlayers() should be the LocalPlayer.

local Players = game.Players
local Assumed_lp: string = Players:GetPlayers()[1].Name
local Real_lp = Players.LocalPlayer.Name

if Assumed_lp ~= Real_lp then
    error("dtc")
else
    print("hooray")
end
