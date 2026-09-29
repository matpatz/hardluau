local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/pubmain/LinoriaLib/refs/heads/main/Library.lua"))() 
local thememanager = loadstring(game:HttpGet("https://raw.githubusercontent.com/pubmain/LinoriaLib/refs/heads/main/addons/ThemeManager.lua"))() 
local savemanager = loadstring(game:HttpGet("https://raw.githubusercontent.com/pubmain/LinoriaLib/refs/heads/main/addons/SaveManager.lua"))() 

local options = library.Options
local toggles = library.Toggles
library.ToggleKeybind = "Del"

local execname = identifyexecutor() or "Shit-Ware"

local window = library:CreateWindow({
	Title = "Aniphobia | " .. execname,
	Center = true,
	AutoShow = true,
	Resizable = true,
	ShowCustomCursor = true,
	UnlockMouseWhileOpen = true,
	TabPadding = 8,
	MenuFadeTime = 0.5,
	NotifySide = "Right",
	ShowToggleFrameInKeybinds = true,
})

local tabs = {
	main = window:AddTab("main"),
    visuals = window:AddTab("visuals"),
    misc = window:AddTab("misc"),
    config = window:AddTab("configs")
}

local main = tabs.main:AddLeftGroupbox("main")
local itemteleports = tabs.main:AddRightTabbox()
local poiteleports = tabs.main:AddRightGroupbox("poi teleport")
local objectvisuals = tabs.visuals:AddLeftGroupbox("esp visuals")
local worldvisuals = tabs.visuals:AddRightGroupbox("world visuals")
local misc = tabs.misc:AddLeftGroupbox("misc")

local lighting = cloneref(game:GetService("Lighting"))
local runserv = cloneref(game:GetService("RunService"))
local startergui = cloneref(game:GetService("StarterGui"))
local localplayer = cloneref(game:GetService("Players")).LocalPlayer
local character = localplayer.Character
local camera = cloneref(game:GetService("Workspace")).CurrentCamera

local ammocolor = Color3.fromRGB(180, 219, 163)
local lootcolor = Color3.fromRGB(81, 255, 0)
local vehiclecolor = Color3.fromRGB(30, 4, 179)
local waifucolor = Color3.fromRGB(146, 5, 5)
local playercolor = Color3.fromRGB(9, 148, 136)
local playertrans = 0
local waifutrans = 0
local ammotrans = 0
local vehicletrans = 0
local loottrans = 0

local lootespcon
local waifuespcon 
local ammoespcon
local vehicleespcon
local walkspeedcon
local jumppowercon
local infammocon
local playerespcon
local lightingcon
local staffdetectorcon
local meleeauracon

local lootfolder = game:GetService("Workspace"):FindFirstChild("LootItems", true) -- hopefully only one loot folder
local ammofolder = game:GetService("Workspace"):FindFirstChild("AmmoBoxes")
local vehiclefolder = game:GetService("Workspace"):FindFirstChild("Vehicles")
local waifufolder = game:GetService("Workspace"):FindFirstChild("OtherWaifus")

local ogcframe

local oldammo = {}
local oldfirerate = {}
local oldrecoil = {}
local oldpenetration = {}
local oldrun = {}

local oldlighting = {
    Ambient = lighting.Ambient,
    OutdoorAmbient = lighting.OutdoorAmbient,
    Brightness = lighting.Brightness,
    ClockTime = lighting.ClockTime,
    FogColor = lighting.FogColor,
    FogStart = lighting.FogStart,
    FogEnd = lighting.FogEnd,
    GlobalShadows = lighting.GlobalShadows,
    ColorShift_Top = lighting.ColorShift_Top,
    ColorShift_Bottom = lighting.ColorShift_Bottom,
    EnvironmentDiffuseScale = lighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = lighting.EnvironmentSpecularScale,
    ShadowSoftness = lighting.ShadowSoftness
}

local newlighting = {
    Ambient = oldlighting.Ambient,
    OutdoorAmbient = oldlighting.OutdoorAmbient,
    Brightness = oldlighting.Brightness,
    ClockTime = oldlighting.ClockTime,
    FogColor = oldlighting.FogColor,
    FogStart = oldlighting.FogStart,
    FogEnd = oldlighting.FogEnd,
    GlobalShadows = oldlighting.GlobalShadows,
    ColorShift_Top = oldlighting.ColorShift_Top,
    ColorShift_Bottom = oldlighting.ColorShift_Bottom,
    EnvironmentDiffuseScale = oldlighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = oldlighting.EnvironmentSpecularScale,
    ShadowSoftness = oldlighting.ShadowSoftness
}

local pois = { -- idfk what to call them, tried to sort by biome
    Spawn = CFrame.new(5987.57031, 16.5, 1156.05176, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    Chruch = CFrame.new(2801.84644, 115.682617, -3469.67188, 1, -1.10121211e-10, 1.09368284e-05, 1.09052239e-10, 1, 9.77408021e-08, -1.09368284e-05, -9.77408021e-08, 1),
    Garage = CFrame.new(4710.32227, 214.540283, -3484.44849, 0.537308574, 7.04511649e-08, 0.843385696, -1.95816453e-12, 1, -8.35324983e-08, -0.843385696, 4.48810766e-08, 0.537308574),
    Campgrounds = CFrame.new(-3689.74365, 426.016876, 4537.26562, 0.57354486, 7.39772545e-08, 0.81917417, 5.98888439e-11, 1, -9.03490474e-08, -0.81917417, 5.1868291e-08, 0.57354486),
    Town = CFrame.new(2378.50049, 245.499985, -2276.53662, 1, 2.80253043e-10, -5.80242568e-06, -2.80690304e-10, 1, -7.53593952e-08, 5.80242568e-06, 7.53593952e-08, 1),
    GeneralStore = CFrame.new(-1529.76697, 549.602905, -907.772705, 1, 1.02848452e-09, -1.99808583e-05, -1.02773434e-09, 1, 3.75444209e-08, 1.99808583e-05, -3.75443996e-08, 1),
    Town2 = CFrame.new(4032.1228, 214.540283, -4890.06494, 0.0104378518, -7.10990644e-09, 0.999945521, -2.86922552e-09, 1, 7.14024395e-09, -0.999945521, -2.94359803e-09, 0.0104378518),
    Farm = CFrame.new(-2833.5, 212.142212, -4971.66406, 1, -6.80612094e-11, -1.43421803e-05, 6.91225757e-11, 1, 7.40031041e-08, 1.43421803e-05, -7.40031041e-08, 1),
    LittleRedRock = CFrame.new(-1571.7196, 363.837921, 4629.05908, 0.707112789, 3.91231332e-08, 0.707100749, 8.69078698e-11, 1, -5.54158461e-08, -0.707100749, 3.92467072e-08, 0.707112789),
    MilitaryCheckpoint = CFrame.new(2106.74731, 562.060791, 1021.68262, 0.866034448, -6.84037227e-09, 0.499984324, 7.90957369e-11, 1, 1.35441702e-08, -0.499984324, -1.16901715e-08, 0.866034448),
    BigCity = CFrame.new(-2200.21973, 363.834045, 1950.64746, -0.0130356885, 1.0783384e-08, -0.999915004, -1.2999025e-08, 1, 1.09537659e-08, 0.999915004, 1.31407099e-08, -0.0130356885),
    Tunnel =  CFrame.new(75.8673325, 363.838531, 2870.13159, -0.999939263, -5.89948215e-08, -0.0110214977, -5.9181712e-08, 1, 1.66309633e-08, 0.0110214977, 1.72822237e-08, -0.999939263),
    Oilfield = CFrame.new(-1872.19775, 323.040833, 5569.59619, -0.335672826, -3.99522193e-08, -0.941978633, -2.32102977e-08, 1, -3.41421256e-08, 0.941978633, 1.04030207e-08, -0.335672826),
    RangerStation = CFrame.new(-2942.698, 478.68634, 4452.89062, 0.279120117, -1.04641718e-09, -0.960256219, 4.65067496e-09, 1, 2.62096539e-10, 0.960256219, -4.53899585e-09, 0.279120117),
    UnnamedCity = CFrame.new(-4753.72656, 461.458984, 5370.6167, -0.420061201, -1.13679643e-08, 0.907495797, -2.697975e-08, 1, 3.83671185e-11, -0.907495797, -2.44678944e-08, -0.420061201),
    DriveIn = CFrame.new(-3678.05981, 403.437622, 6358.90332, 0.906787574, -4.37712266e-08, 0.421587795, 4.91969532e-09, 1, 9.32429884e-08, -0.421587795, -8.24774986e-08, 0.906787574),
    RadioStation = CFrame.new(1677.93359, 728.692566, -467.033844, 0.999978244, 1.4129669e-08, 0.0065926956, -1.37665781e-08, 1, -5.51200827e-08, -0.0065926956, 5.50281278e-08, 0.999978244),
    Woodmill = CFrame.new(3412.73047, 702.275269, 171.531189, -0.252075523, 5.88380651e-08, -0.967707574, -1.10960912e-08, 1, 6.36918855e-08, 0.967707574, 2.67929359e-08, -0.252075523),
    GoldRushCasino = CFrame.new(4354.12939, 702.275757, -1386.62708, -0.829878628, 6.86719162e-08, -0.557944, 2.46416203e-08, 1, 8.64286775e-08, 0.557944, 5.79766706e-08, -0.829878628),
    Bridge = CFrame.new(4321.82959, 214.540283, -2877.57959, 0.532867968, 1.49249484e-08, 0.84619838, -3.67798272e-08, 1, 5.52334312e-09, -0.84619838, -3.40662432e-08, 0.532867968),
    MiningSite = CFrame.new(-5033.01465, 609.094666, -1250.09045, -0.350035757, -4.61072815e-08, 0.936736345, 2.76262035e-09, 1, 5.02535187e-08, -0.936736345, 2.01783745e-08, -0.350035757),
    Junkyard = CFrame.new(-3703.76221, 268.084229, 1932.23645, 0.99996525, -5.82172852e-11, -0.00833883509, 1.83872292e-10, 1, 1.50678865e-08, 0.00833883509, -1.50688955e-08, 0.99996525),
    TumbleWeed = CFrame.new(-8293.91211, 212.621979, 870.174561, -0.863627434, -5.0147321e-08, -0.504130602, -4.78630504e-08, 1, -1.74785573e-08, 0.504130602, 9.03426756e-09, -0.863627434),
    Racetrack = CFrame.new(-5982.41406, 212.633423, -2887.49341, -0.998292863, -9.12524545e-09, -0.0584069118, -6.32177954e-09, 1, -4.81836473e-08, 0.0584069118, -4.77321542e-08, -0.998292863),
    DesertGasStation = CFrame.new(-7360.72705, 212.628632, -2373.35767, 0.906328142, -3.90909989e-08, 0.42257461, 1.89837417e-11, 1, 9.24660171e-08, -0.42257461, -8.37965359e-08, 0.906328142),
    DesertCheckpoint = CFrame.new(-8354.36621, 212.623657, -619.24707, -0.999991655, 6.8980438e-10, -0.00409051264, 6.89012403e-10, 1, 1.95022998e-10, 0.00409051264, 1.92202948e-10, -0.999991655),
    MilitaryBase = CFrame.new(-5470.07178, 212.650604, -5007.16455, -0.00476636924, -2.09601261e-08, 0.999988616, -3.77700218e-08, 1, 2.07803357e-08, -0.999988616, -3.76705458e-08, -0.00476636924),
    Silo = CFrame.new(-8544.0459, 256.574188, -3617.67554, 0.645818174, -7.09905663e-08, 0.763491273, 3.76430798e-08, 1, 6.11401632e-08, -0.763491273, -1.0745266e-08, 0.645818174),
    Prison = CFrame.new(-6919.08643, 268.078186, 1932.01428, 0.999997973, -4.04168681e-08, 0.00202428736, 4.03272509e-08, 1, 4.43114843e-08, -0.00202428736, -4.42297612e-08, 0.999997973),
    PowerPlant = CFrame.new(-5271.32617, 268.081787, 1386.19324, 0.999946952, -1.8482579e-08, -0.0102981143, 1.91460803e-08, 1, 6.43307558e-08, 0.0102981143, -6.45245137e-08, 0.999946952),
    Mansion = CFrame.new(544.336853, 212.651062, -4101.25244, 0.0201368686, -2.18897398e-08, -0.999797225, 9.08551545e-09, 1, -2.17111893e-08, 0.999797225, -8.64647731e-09, 0.0201368686),
    InsideSilo = CFrame.new(-8786.00684, 240.073883, -3728.62671, -0.77181226, -4.15307682e-08, 0.635850489, -1.52182018e-08, 1, 4.68430486e-08, -0.635850489, 2.64775384e-08, -0.77181226),
    NukeLaunchRoom = CFrame.new(-8743.53809, 219.07373, -3843.15747, -0.626683116, 5.10456886e-08, -0.779274166, 1.17298548e-07, 1, -2.88259674e-08, 0.779274166, -1.09472474e-07, -0.626683116),
}

local poinames = {
    "Spawn",
    "Chruch",
    "Garage",
    "Campgrounds",
    "Town",
    "GeneralStore",
    "Town2",
    "Farm" ,
    "LittleRedRock",
    "MilitaryCheckpoint",
    "BigCity",
    "Tunnel",
    "Oilfield",
    "RangerStation",
    "UnnamedCity",
    "DriveIn",
    "RadioStation",
    "Woodmill",
    "GoldRushCasino",
    "Bridge",
    "MiningSite",
    'Junkyard',
    "TumbleWeed",
    "Racetrack",
    "DesertGasStation",
    "DesertCheckpoint",
    "MilitaryBase",
    "Silo",
    "Prison",
    "PowerPlant",
    "Mansion", 
    "InsideSilo",
    "NukeLaunchRoom"    
}

local infammo = false
local rapidfire = false
local norecoil = false
local infpenetration = false
local runwithgun = false

local silentaim = false

local firerate = 0.015

-- no reason to seperate ts with a do end but i will
do
    local prediction = loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/src/libraries/prediction.lua"))() -- i cant make prediction
   	local projectilehandler = require(game:GetService("ReplicatedStorage"):FindFirstChild("Modules"):WaitForChild("ProjectileHandler"))
    local getsettings = require(game:GetService("ReplicatedStorage"):FindFirstChild("Modules"):WaitForChild("GetSetting"))
    local ogprojectilesim = projectilehandler.SimulateProjectile

    local maxdistance = 2500
    local silenttype = "mouse"
    local hitbox = "Head"
    local fov = 30

    -- ts so scuffed bro
    local function getsexiestwaifu()
        if not localplayer.Character then return nil end
        
        local sexiestwaifu, bestboobs = nil, math.huge
        local fovdis = (camera.ViewportSize.Magnitude / 2) * (fov / 180)
        local mousepos = game:GetService("UserInputService"):GetMouseLocation()
        local selfroot = localplayer and localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart")
        
        for _,w in waifufolder:GetChildren() do
            if w:IsA("Model") then
                local waifu = w

                local hum = waifu and waifu:FindFirstChildOfClass("Humanoid")
                local root = waifu and waifu:FindFirstChild("HumanoidRootPart")

                if not root then continue end
                if not hum then continue end
                if hum and hum.Health <= 0 then continue end
                if hum and hum:GetState() == Enum.HumanoidStateType.Dead then continue end

                if waifu and root and hum and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead then -- double check because ts so scuffed it magdumps dead bodies????
                    if silenttype == "mouse" then
                        local screenpos, screen = camera:WorldToViewportPoint(root.Position)
                            if screen then
                                local dis = (Vector2.new(screenpos.X, screenpos.Y) - mousepos).Magnitude

                                if dis and dis <= fovdis and dis < bestboobs then
                                    bestboobs = dis
                                    sexiestwaifu = waifu
                                end
                            end
                        end
                    end

                    if silenttype == "position" then
                        local dis = (root.Position - selfroot.Position).Magnitude

                        if dis and maxdistance == 0 then
                            if dis < bestboobs then
                                bestboobs = dis
                                sexiestwaifu = waifu
                            end
                        end

                        if dis and maxdistance > 0 then
                            if dis <= maxdistance and dis < bestboobs then
                                bestboobs = dis
                                sexiestwaifu = waifu
                            end
                        end
                    end
                end
            end
        return sexiestwaifu
    end

    local function getbulletspeed(tool, misc)
        local settings = getsettings(tool, {ModuleName = misc.ModuleName, ModNames = misc.ModNames, BulletId = misc.BulletId}, nil, nil) -- if u dont pass ts 1:1 it whines and cries

        if settings.ChargedShotAdvanceEnabled and settings.ChargeAlterTable then
            local level = misc.ChargeLevel or 1
            local bulletspeed = settings.ChargeAlterTable.BulletSpeed
            if bulletspeed then
                if level == 1 and bulletspeed.Level1 then return bulletspeed.Level1 end
                if level == 2 and bulletspeed.Level2 then return bulletspeed.Level2 end
                if level == 3 and bulletspeed.Level3 then return bulletspeed.Level3 end
            end
        end

        return settings.BulletSpeed
    end

    projectilehandler.SimulateProjectile = function(v1, tool, v3, bullets, muzzle, v6, misc, replicate)
        if silentaim and replicate and type(bullets) == "table" and muzzle then
            local sexywaifu = getsexiestwaifu()
            if sexywaifu and sexywaifu:FindFirstChild(hitbox) then
                local origin = (muzzle.WorldPosition or muzzle.Position)
                local bulletspeed = getbulletspeed(tool, misc)
                local hitpart = sexywaifu:FindFirstChild(hitbox)
                local root = sexywaifu:FindFirstChild("HumanoidRootPart")
                
                if root and hitpart and origin and bulletspeed then
                    local predictedpos = prediction and prediction.SolveTrajectory(origin, bulletspeed, game:GetService("Workspace").Gravity, hitpart.Position, root.Velocity, nil, nil, nil, nil)
                    local dir = (predictedpos - origin).Unit

                    for _, b in bullets do
                        if type(b) == "table" then b[1] = dir end
                    end
                end
            end
        end
        return ogprojectilesim(v1, tool, v3, bullets, muzzle, v6, misc, replicate)
    end
    
    main:AddToggle('silentaim',{
        Default = false,
        Text = "silentaim",
        Tooltip = "redirects your bullet to the nearest enemy",
        Callback = function(v)
            silentaim = v
        end
    })

    main:AddDropdown('hitbox',{
		Values = {"Head", "Torso", "HumanoidRootPart",},
		Default = "Head",
		Multi = false,
		Text = "hitbox",
        Tooltip = "the part which silentaim will redirect to",
		Callback = function(v)  
            hitbox = v
		end
	})

    main:AddDropdown('silenttype',{
		Values = {"mouse", "position"},
		Default = "mouse",
		Multi = false,
		Text = "silent type",
        Tooltip = "mouse gets closest to your mouse, position gets closest around you (ignores fov)",
		Callback = function(v)  
            silenttype = v

            if v == 'mouse' then
                options.silentfov:SetVisible(true)
                options.silentdistance:SetVisible(false)
            else
                options.silentfov:SetVisible(false)
                options.silentdistance:SetVisible(true)
            end
		end
	})

    main:AddSlider('silentdistance',{
        Min = 0,
        Max = 10000,
        Rounding = 0,
        Default = 2500,
        Compact = true,
        Text = "distance",
        Visible = false,
        Tooltip = "maxmium distance that silent will redirect at (0 means silent will redirect no matter the distance)",
        Callback = function(v) 
            maxdistance = v
        end
    })

    main:AddSlider('silentfov',{
        Min = 1,
        Max = 180,
        Rounding = 0,
        Default = 30,
        Compact = true,
        Text = "silent fov",
        Visible = true,
        Tooltip = "the fov that silentaim will use to redirect",
        Callback = function(v) 
            fov = v
        end
    })

    main:AddDivider()
end

do
    local melee = game:GetService("ReplicatedStorage"):FindFirstChild("MeleeSystem"):WaitForChild("MeleeEvent")
    local maxdistance = 12
    local cooldown = 0.5
    local lastswing = 0

    main:AddToggle('meleeaura',{
        Default = false,
        Text = "melee aura",
        Tooltip = "hits any enemy within a certain distance",
        Callback = function(v)
            options.meleeauradistance:SetVisible(v)
            options.meleeauracooldown:SetVisible(v)

            if v then
                meleeauracon = runserv.Heartbeat:Connect(function()
                    local tool = localplayer and localplayer.Character and localplayer.Character:FindFirstChildOfClass("Tool")

                    if tool and tool:FindFirstChild("MeleeHitbox") then
                        for _,v in waifufolder:GetChildren() do
                            if localplayer and localplayer.Character and v then
                                local root = v and v:FindFirstChild("HumanoidRootPart")
                                local hum = v and v:FindFirstChildOfClass("Humanoid")
                                local selfroot = localplayer and localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart")

                                if v and root and hum and selfroot and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                                    local currentdistance = (root.Position - selfroot.Position).Magnitude

                                    if v and currentdistance <= maxdistance and tick() - cooldown >= lastswing then
                                        lastswing = tick()

                                        melee:FireServer(
                                            "hit",
                                            {
                                                v
                                            }
                                        )
                                    end
                                end
                            end
                        end
                    end
                end)
            else
                if meleeauracon then
                    meleeauracon:Disconnect()
                    meleeauracon = nil
                end
            end
        end
    })

    main:AddSlider('meleeauradistance',{
        Min = 1,
        Max = 12,
        Rounding = 1,
        Default = maxdistance,
        Compact = true,
        Text = "distance",
        Visible = false,
        Tooltip = "how close a enemy needs to be for melee aura to hit them",
        Callback = function(v) 
            maxdistance = v
        end
    })
    main:AddSlider('meleeauracooldown',{
        Min = 0,
        Max = 1,
        Rounding = 1,
        Default = cooldown,
        Compact = true,
        Text = "cooldown",
        Visible = false,
        Tooltip = "cooldown between melee aura hits",
        Callback = function(v) 
            cooldown = v
        end
    })

    main:AddDivider()
end

main:AddToggle('infiniteammo',{
    Default = false,
    Text = "infinite ammo",
    Tooltip = "prevents your gun from losing ammo when firing",
    Callback = function(v)
        infammo = v

        if v then
            for _,v in filtergc("table",{Keys = {"AmmoCost", "AmmoPerMag"}}) do
                if not oldammo[v] then
                    oldammo[v] = {v.AmmoCost, v.LimitedAmmoEnabled}
                end

                setreadonly(v, false)
                v.AmmoCost = 0 
                v.LimitedAmmoEnabled = false
                setreadonly(v, true)
            end
        else
            for i,v in oldammo do
                setreadonly(i, false)
                i.LimitedAmmoEnabled = v[2] 
                i.AmmoCost = v[1]
                setreadonly(i, true)
            end
        end
    end
})
main:AddToggle('rapidfire',{
    Default = false,
    Text = "rapid fire",
    Tooltip = "lets you customize the firerate of guns (lower your volume as much as possible pls)",
    Callback = function(v)
        rapidfire = v
        options.firerate:SetVisible(v)

        if v then
            for _,v in filtergc("table",{Keys = {"FireRate", "MaximumFireRate", "FireRateIncrement", "DelayBeforeFiring", "DelayAfterFiring", "Auto", "ChargingTime", "ShotgunPumpinSpeed", "LaserBeamStartupDelay", "LaserBeamStopDelay"}}) do
                if not oldfirerate[v] then
                    oldfirerate[v] = {v.FireRate, v.MaximumFireRate, v.FireRateIncrement, v.DelayBeforeFiring, v.DelayAfterFiring, v.Auto, v.ChargingTime, v.ShotgunPumpinSpeed, v.LaserBeamStartupDelay, v.LaserBeamStopDelay}
                end

                setreadonly(v, false)
                v.FireRate = firerate
                v.MaximumFireRate = firerate
                v.FireRateIncrement = 0
                v.DelayBeforeFiring = 0
                v.DelayAfterFiring = 0
                v.Auto = true
                v.ChargingTime = 0
                v.ShotgunPumpinSpeed = 0
                v.LaserBeamStartupDelay = 0
                v.LaserBeamStopDelay = 0
                setreadonly(v, true)
            end
        else
            for i,v in oldfirerate do
                setreadonly(i, false)
                i.FireRate = v[1] 
                i.MaximumFireRate = v[2]
                i.FireRateIncrement = v[3]
                i.DelayBeforeFiring = v[4]
                i.DelayAfterFiring = v[5]
                i.Auto = v[6]
                v.ChargingTime = v[7]
                v.ShotgunPumpinSpeed = v[8]
                v.LaserBeamStartupDelay = v[9]
                v.LaserBeamStopDelay = v[10]
                setreadonly(i, true)
            end
        end
    end
})
main:AddSlider('firerate',{
    Min = 0,
    Max = 1,
    Rounding = 2,
    Default = firerate,
    Compact = true,
    Text = "firerate",
    Visible = false,
    Tooltip = "lets you change the firerate rapid fire uses (low values = earrape)",
    Callback = function(v) 
        firerate = v

        for _,t in filtergc("table",{Keys = {"FireRate", "MaximumFireRate"}}) do
            setreadonly(t, false)
            t.FireRate = firerate
            t.MaximumFireRate = firerate
            setreadonly(t, true)
        end
    end
})
main:AddToggle('no recoil',{
    Default = false,
    Text = "no recoil",
    Tooltip = "prevents screen from shaking when firing",
    Callback = function(v)
        norecoil = v

        if v then
            for _,v in filtergc("table",{Keys = {"Recoil"}}) do
                if not oldrecoil[v] then
                    oldrecoil[v] = {v.Recoil}
                end

                setreadonly(v, false)
                v.Recoil = 0
                setreadonly(v, true)
            end
        else
            for i,v in oldrecoil do
                setreadonly(i, false)
                i.Recoil = v[1] 
                setreadonly(i, true)
            end
        end
    end
})
main:AddToggle('infinite penetration',{
    Default = false,
    Text = "infinite penetration",
    Tooltip = "lets your bullets penetrate most objects/terrain (works best with snipers)",
    Callback = function(v)
        infpenetration = v

        if v then
            for _,v in filtergc("table",{Keys = {"PenetrationAmount", "PenetrationDepth", "DamageThroughWall", "IgnoreHumanoids"}}) do
                if not oldpenetration[v] then
                    oldpenetration[v] = {v.PenetrationAmount, v.PenetrationDepth, v.DamageThroughWall, v.IgnoreHumanoids}
                end

                setreadonly(v, false)
                v.PenetrationAmount = 9e9
                v.PenetrationDepth  = 9e9
                v.DamageThroughWall = true
                v.IgnoreHumanoids   = false
                setreadonly(v, true)
            end
        else
            for i,v in oldpenetration do
                setreadonly(i, false)
                i.PenetrationAmount = v[1]
                i.PenetrationDepth  = v[2]
                i.DamageThroughWall = v[3]
                i.IgnoreHumanoids   = v[4] 
                setreadonly(i, true)
            end
        end
    end
})
main:AddToggle('runwithgun',{
    Default = false,
    Text = "run with gun",
    Tooltip = "lets you shoot and sprint",
    Callback = function(v)
        runwithgun = v

        if v then
            for _,v in filtergc("table",{Keys = {"HoldDownEnabled"}}) do
                if not oldrun[v] then
                    oldrun[v] = {v.HoldDownEnabled}
                end

                setreadonly(v, false)
                v.HoldDownEnabled = false
                setreadonly(v, true)
            end
        else
            for i,v in oldrun do
                setreadonly(i, false)
                i.HoldDownEnabled = v[1]
                setreadonly(i, true)
            end
        end
    end
})

main:AddDivider()

infammocon = localplayer.DescendantAdded:Connect(function(c)
    task.wait(0.5) -- sometime for weapon logic

    if c:IsA("Tool") and c:FindFirstChild("GunClient") then
        if infammo then
            for _,v in filtergc("table",{Keys = {"AmmoCost", "AmmoPerMag"}}) do
                if not oldammo[v] then
                    oldammo[v] = {v.AmmoCost, v.LimitedAmmoEnabled}
                end

                setreadonly(v, false)
                v.AmmoCost = 0 
                v.LimitedAmmoEnabled = false
                setreadonly(v, true)
            end
        end

        if rapidfire then
            for _,v in filtergc("table",{Keys = {"FireRate", "MaximumFireRate", "FireRateIncrement", "DelayBeforeFiring", "DelayAfterFiring", "Auto", "ChargingTime", "ShotgunPumpinSpeed", "LaserBeamStartupDelay", "LaserBeamStopDelay"}}) do
                if not oldfirerate[v] then
                    oldfirerate[v] = {v.FireRate, v.MaximumFireRate, v.FireRateIncrement, v.DelayBeforeFiring, v.DelayAfterFiring, v.Auto, v.ChargingTime, v.ShotgunPumpinSpeed, v.LaserBeamStartupDelay, v.LaserBeamStopDelay}
                end

                setreadonly(v, false)
                v.FireRate = firerate 
                v.MaximumFireRate = firerate
                v.FireRateIncrement = 0
                v.DelayBeforeFiring = 0
                v.DelayAfterFiring = 0
                v.Auto = true
                v.ChargingTime = 0
                v.ShotgunPumpinSpeed = 0
                v.LaserBeamStartupDelay = 0
                v.LaserBeamStopDelay = 0
                setreadonly(v, true)
            end
        end

        if norecoil then
            for _,v in filtergc("table",{Keys = {"Recoil"}}) do
                if not oldrecoil[v] then
                    oldrecoil[v] = {v.Recoil}
                end

                setreadonly(v, false)
                v.Recoil = 0
                setreadonly(v, true)
            end
        end

        if infpenetration then
            for _,v in filtergc("table",{Keys = {"PenetrationAmount", "PenetrationDepth", "DamageThroughWall", "IgnoreHumanoids"}}) do
                if not oldpenetration[v] then
                    oldpenetration[v] = {v.PenetrationAmount, v.PenetrationDepth, v.DamageThroughWall, v.IgnoreHumanoids}
                end

                setreadonly(v, false)
                v.PenetrationAmount = math.huge
                v.PenetrationDepth  = math.huge
                v.DamageThroughWall = true
                v.IgnoreHumanoids   = false
                setreadonly(v, true)
            end
        end

        if runwithgun then
            for _,v in filtergc("table",{Keys = {"HoldDownEnabled"}}) do
                if not oldrun[v] then
                    oldrun[v] = {v.HoldDownEnabled}
                end

                setreadonly(v, false)
                v.HoldDownEnabled = false
                setreadonly(v, true)
            end
        end
    end
end)



do
    local loottab = itemteleports:AddTab("loot")
    local teleportobject
    local loot = {}

    local function getloot()
        table.clear(loot)

        for _,v in lootfolder:GetChildren() do -- ui lib treats object with same name as same entry ffs, would do counting method but debugid is easier and shorter
            if v and v.Name then
                local uid = v.Name .. v:GetDebugId()
                table.insert(loot, uid)
            end
        end
    end

    loottab:AddDropdown('lootobjects',{
		Values = loot,
		Default = loot[1] or "None",
		Multi = false,
		Text = "loot object",
		Callback = function(v)
            for _,l in lootfolder:GetChildren() do
                if string.find(v, l.Name) then
                    teleportobject = l
                end
            end
		end
	})

    lootteleport = loottab:AddButton({
        Text = "teleport",
        Func = function()
            if localplayer and localplayer.Character and teleportobject ~= nil then
                localplayer.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(teleportobject.Position)
            end
        end,
        DoubleClick = false,
        Visible = true
    })

    refreshdropdown = loottab:AddButton({
        Text = "refresh",
        Func = function()
            teleportobject = nil
            options.lootobjects:SetValues({})
            getloot()
            options.lootobjects:SetValues(loot)
        end,
        DoubleClick = false,
        Visible = true
    })

    loottab:AddDivider()

    saveoldcframe = loottab:AddButton({
        Text = "save cframe",
        Func = function()
            if localplayer and localplayer.Character then
                ogcframe = localplayer.Character:FindFirstChild("HumanoidRootPart").CFrame
            end
        end,
        DoubleClick = false,
        Visible = true
    })

    teleportooldcframe = loottab:AddButton({
        Text = "teleport to old cframe",
        Func = function()
            if localplayer and localplayer.Character and ogcframe then
                localplayer.Character:FindFirstChild("HumanoidRootPart").CFrame = ogcframe
            end
        end,
        DoubleClick = false,
        Visible = true
    })
end

do
    local ammotab = itemteleports:AddTab("ammo")
    local teleportobject
    local ammo = {}

    local function getloot()
        table.clear(ammo)

        for _,v in ammofolder:GetChildren() do
            if v and v.Name then
                local uid = v.Name .. v:GetDebugId()
                table.insert(ammo, uid)
            end
        end
    end

    ammotab:AddDropdown('ammoobjects',{
		Values = ammo,
		Default = ammo[1] or "None",
		Multi = false,
		Text = "loot object",
		Callback = function(v)
            for _,l in ammofolder:GetChildren() do
                if string.find(v, l.Name) then
                    teleportobject = l
                end
            end
		end
	})

    ammoteleport = ammotab:AddButton({
        Text = "teleport",
        Func = function()
            if localplayer and localplayer.Character and teleportobject ~= nil then
                localplayer.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(teleportobject.Position)
            end
        end,
        DoubleClick = false,
        Visible = true
    })

    refreshdropdown = ammotab:AddButton({
        Text = "refresh",
        Func = function()
            teleportobject = nil
            options.ammoobjects:SetValues({})
            getloot()
            options.ammoobjects:SetValues(ammo)
        end,
        DoubleClick = false,
        Visible = true
    })

    ammotab:AddDivider()

    saveoldcframe = ammotab:AddButton({
        Text = "save cframe",
        Func = function()
            if localplayer and localplayer.Character then
                ogcframe = localplayer.Character:FindFirstChild("HumanoidRootPart").CFrame
            end
        end,
        DoubleClick = false,
        Visible = true
    })

    teleportooldcframe = ammotab:AddButton({
        Text = "teleport to old cframe",
        Func = function()
            if localplayer and localplayer.Character and ogcframe then
                localplayer.Character:FindFirstChild("HumanoidRootPart").CFrame = ogcframe
            end
        end,
        DoubleClick = false,
        Visible = true
    })
end

do
    local vehicletab = itemteleports:AddTab("vehicle")
    local teleportobject
    local vehicles = {}

    local function getloot()
        table.clear(vehicles)

        for _,v in vehiclefolder:GetChildren() do
            if v and v.Name then
                local uid = v.Name .. v:GetDebugId()
                table.insert(vehicles, uid)
            end
        end
    end

    vehicletab:AddDropdown('vehicleobjects',{
		Values = vehicles,
		Default = vehicles[1] or "None",
		Multi = false,
		Text = "vehicle object",
		Callback = function(v)
            for _,l in vehiclefolder:GetChildren() do
                if string.find(v, l.Name) then
                    teleportobject = l
                end
            end
		end
	})

    vehicleteleport = vehicletab:AddButton({
        Text = "teleport",
        Func = function()
            if localplayer and localplayer.Character and teleportobject ~= nil then
                localplayer.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(teleportobject:GetPivot().Position)
            end
        end,
        DoubleClick = false,
        Visible = true
    })

    refreshdropdown = vehicletab:AddButton({
        Text = "refresh",
        Func = function()
            teleportobject = nil
            options.vehicleobjects:SetValues({})
            getloot()
            options.vehicleobjects:SetValues(vehicles)
        end,
        DoubleClick = false,
        Visible = true
    })

    vehicletab:AddDivider()

    saveoldcframe = vehicletab:AddButton({
        Text = "save cframe",
        Func = function()
            if localplayer and localplayer.Character then
                ogcframe = localplayer.Character:FindFirstChild("HumanoidRootPart").CFrame
            end
        end,
        DoubleClick = false,
        Visible = true
    })

    teleportooldcframe = vehicletab:AddButton({
        Text = "teleport to old cframe",
        Func = function()
            if localplayer and localplayer.Character and ogcframe then
                localplayer.Character:FindFirstChild("HumanoidRootPart").CFrame = ogcframe
            end
        end,
        DoubleClick = false,
        Visible = true
    })
end

do
    local selectedpoi = pois.Spawn or nil

    poiteleports:AddDropdown('pois',{
		Values = poinames,
		Default = poinames[1] or "None",
		Multi = false,
		Text = "selected poi",
		Callback = function(v)
            selectedpoi = pois[v]
		end
	})

    poiteleport = poiteleports:AddButton({
        Text = "teleport",
        Func = function()
            if localplayer and localplayer.Character and selectedpoi ~= nil then
                localplayer.Character:FindFirstChild("HumanoidRootPart").CFrame = selectedpoi
            end
        end,
        DoubleClick = false,
        Visible = true
    })

    poiteleports:AddDivider()

    saveoldcframe = poiteleports:AddButton({
        Text = "save cframe",
        Func = function()
            if localplayer and localplayer.Character then
                ogcframe = localplayer.Character:FindFirstChild("HumanoidRootPart").CFrame
            end
        end,
        DoubleClick = false,
        Visible = true
    })

    teleportooldcframe = poiteleports:AddButton({
        Text = "teleport to old cframe",
        Func = function()
            if localplayer and localplayer.Character and ogcframe then
                localplayer.Character:FindFirstChild("HumanoidRootPart").CFrame = ogcframe
            end
        end,
        DoubleClick = false,
        Visible = true
    })
end

do
    local jumppower = 20
    local walkspeed = 18

    main:AddToggle('walkspeedoverride',{
        Default = false,
        Text = "walkspeed override",
        Callback = function(v)
            options.walkspeed:SetVisible(v)

            if v then
                walkspeedcon = runserv.Heartbeat:Connect(function()
                    if localplayer and localplayer.Character then
                        local hum = localplayer and localplayer.Character and localplayer.Character:FindFirstChildOfClass("Humanoid")

                        if hum and hum.WalkSpeed and hum.WalkSpeed ~= walkspeed then
                            hum.WalkSpeed = walkspeed
                        end
                    end
                end)
            else
                if walkspeedcon then
                    walkspeedcon:Disconnect()
                    walkspeedcon = nil
                end
            end
        end
    })
    main:AddSlider('walkspeed',{
        Min = 1,
        Max = 500,
        Rounding = 0,
        Default = walkspeed,
        Compact = true,
        Text = "walkspeed",
        Visible = false,
        Callback = function(v) 
            walkspeed = v
        end
    })

    main:AddToggle('jumppoweroverride',{
        Default = false,
        Text = "jumppower override",
        Callback = function(v)
            options.jumppower:SetVisible(v)
            
            if v then
                jumppowercon = runserv.Heartbeat:Connect(function()
                    if localplayer and localplayer.Character then
                        local hum = localplayer and localplayer.Character and localplayer.Character:FindFirstChildOfClass("Humanoid")

                        if hum and hum.JumpPower and hum.JumpPower ~= jumppower then
                            hum.JumpPower = jumppower
                        end
                    end
                end)
            else
                if jumppowercon then
                    jumppowercon:Disconnect()
                    jumppowercon = nil
                end
            end
        end
    })
    main:AddSlider('jumppower',{
        Min = 1,
        Max = 350,
        Rounding = 0,
        Default = jumppower,
        Compact = true,
        Text = "jump power",
        Visible = false,
        Callback = function(v) 
            jumppower = v
        end
    })
end

misc:AddToggle('staffdetector',{
    Default = false,
    Text =  "staff detector",
    Tooltip = "notifies you when staff joins your server or is already in your server",
    Callback = function(v)
        if v then
            staffdetectorcon = game:GetService("Players").PlayerAdded:Connect(function(p) 
                if p then
                    local rank = p:GetRoleInGroup(10668871)

                    if rank == "Guest" then return end
                    if rank == "Verified" then return end
                    if rank == "Influencer" then return end

                    if rank then
                        local msg = "staff joined " .. "(" .. p.Name .. ", " .. rank ..")"

                        if msg then
                            library:Notify({
                                Title = "staff detector",
                                Description = msg,
                                Time = 5,
                            })
                        end
                    end
                end
            end)

            for _,p in game:GetService("Players"):GetPlayers() do
                if p then
                    local rank = p:GetRoleInGroup(10668871)

                    if rank == "Guest" then return end
                    if rank == "Verified" then return end
                    if rank == "Influencer" then return end

                    if rank then
                        local msg = "staff found " .. "(" .. p.Name .. ", " .. rank ..")"

                        if msg then
                            library:Notify({
                                Title = "staff detector",
                                Description = msg,
                                Time = 5,
                            })
                        end
                    end
                end
            end
        else
            if staffdetectorcon then
                staffdetectorcon:Disconnect()
                staffdetectorcon = nil
            end
        end
    end
})

objectvisuals:AddToggle('waifuesp',{
    Default = false,
    Text = "waifu esp",
    Callback = function(v)
        if v then
            for _,w in waifufolder:GetChildren() do
                if w and w:FindFirstChildOfClass("Highlight") then
                    w:FindFirstChildOfClass("Highlight").Enabled = true
                end

                if w and not w:FindFirstChildOfClass("Highlight") then
                    local high = Instance.new("Highlight")

                    high.Parent = w
                    high.Adornee = w
                    high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    high.OutlineColor = waifucolor
                    high.OutlineTransparency = waifutrans
                    high.FillColor = waifucolor
                    high.FillTransparency = waifutrans
                end
            end

            waifuespcon = waifufolder.ChildAdded:Connect(function(w)
                if w and not w:FindFirstChildOfClass("Highlight") then
                    local high = Instance.new("Highlight")

                    high.Parent = w
                    high.Adornee = w
                    high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    high.OutlineColor = waifucolor
                    high.OutlineTransparency = waifutrans
                    high.FillColor = waifucolor
                    high.FillTransparency = waifutrans
                end
            end)
        else
            for _,w in waifufolder:GetChildren() do
                if w and w:FindFirstChildOfClass("Highlight") then
                    w:FindFirstChildOfClass("Highlight").Enabled = false
                end
            end

            if waifuespcon then
                waifuespcon:Disconnect()
                waifuespcon = nil
            end
        end
    end
})
objectvisuals:AddLabel('waifu color'):AddColorPicker('waifucolor',{
    Title = "waifu color",
    Default =  waifucolor,
    Callback = function(c)
        waifucolor = c

        for _,v in waifufolder:GetChildren() do
            if v and v:FindFirstChildOfClass("Highlight") then
                v:FindFirstChildOfClass("Highlight").FillColor = waifucolor
                v:FindFirstChildOfClass("Highlight").OutlineColor = waifucolor
            end
        end
    end
})
objectvisuals:AddSlider('waifuesptrans',{
    Min = 0,
    Max = 1,
    Rounding = 2,
    Default = waifutrans,
    Compact = true,
    Text = "waifu transparency",
    Callback = function(v) 
        waifutrans = v

        for _,v in waifufolder:GetChildren() do
            if v and v:FindFirstChildOfClass("Highlight") then
                v:FindFirstChildOfClass("Highlight").FillTransparency = waifutrans
                v:FindFirstChildOfClass("Highlight").OutlineTransparency = waifutrans
            end
        end
    end
})

objectvisuals:AddDivider()

-- ts beautiful gng😭👍
objectvisuals:AddToggle('playeresp',{
    Default = false,
    Text = "player esp",
    Callback = function(v)
        if v then
            playerespcon = game:GetService("Workspace").ChildAdded:Connect(function(p)
                for _,plr in game:GetService("Players"):GetPlayers() do -- v, p and plr ig bro
                    if p and plr and plr.Name == p.Name and p.Name ~= localplayer.Name then
                        if p and not p:FindFirstChildOfClass("Highlight") then
                            local high = Instance.new("Highlight")

                            high.Parent = p
                            high.Adornee = p
                            high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            high.OutlineColor = playercolor
                            high.OutlineTransparency = playertrans
                            high.FillColor = playercolor
                            high.FillTransparency = playertrans
                        end
                    end
                end
            end)

            for _,p in game:GetService("Players"):GetPlayers() do
                if p and p.Character and p ~= localplayer then
                    if p and p.Character and p.Character:FindFirstChildOfClass("Highlight") then
                        p.Character:FindFirstChildOfClass("Highlight").Enabled = true
                    end 

                    if p and p.Character and not p.Character:FindFirstChildOfClass("Highlight") then
                        local high = Instance.new("Highlight")

                        high.Parent = p.Character
                        high.Adornee = p.Character
                        high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        high.OutlineColor = playercolor
                        high.OutlineTransparency = playertrans
                        high.FillColor = playercolor
                        high.FillTransparency = playertrans
                    end 
                end
            end
        else
            for _,p in game:GetService("Players"):GetPlayers() do
                if p and p.Character then
                    if p and p.Character and p.Character:FindFirstChildOfClass("Highlight") then
                        p.Character:FindFirstChildOfClass("Highlight").Enabled = false
                    end 
                end
            end
        end
    end
})
objectvisuals:AddLabel('player color'):AddColorPicker('playercolor',{
    Title = "player color",
    Default =  playercolor,
    Callback = function(c)
        playercolor = c

        for _,v in game:GetService("Players"):GetPlayers() do
            if v and v.Character then
                if v and v.Character and v.Character:FindFirstChildOfClass("Highlight") then
                    v.Character:FindFirstChildOfClass("Highlight").FillColor = playercolor
                    v.Character:FindFirstChildOfClass("Highlight").OutlineColor = playercolor
                end 
            end
        end
    end
})
objectvisuals:AddSlider('playeresptrans',{
    Min = 0,
    Max = 1,
    Rounding = 2,
    Default = playertrans,
    Compact = true,
    Text = "player transparency",
    Callback = function(v) 
        playertrans = v

        for _,v in game:GetService("Players"):GetPlayers() do
            if v and v.Character then
                if v and v.Character and v.Character:FindFirstChildOfClass("Highlight") then
                    v.Character:FindFirstChildOfClass("Highlight").OutlineTransparency = playertrans
                    v.Character:FindFirstChildOfClass("Highlight").FillTransparency = playertrans
                end 
            end
        end
    end
})

objectvisuals:AddDivider()

objectvisuals:AddToggle('lootesp',{
    Default = false,
    Text = "loot esp",
    Callback = function(v)
        if v then
            for _,l in lootfolder:GetChildren() do
                if l and l:FindFirstChildOfClass("Highlight") then
                    l:FindFirstChildOfClass("Highlight").Enabled = true
                end

                if l and not l:FindFirstChildOfClass("Highlight") then
                    local high = Instance.new("Highlight")

                    high.Parent = l
                    high.Adornee = l
                    high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    high.OutlineColor = lootcolor
                    high.OutlineTransparency = loottrans
                    high.FillColor = lootcolor
                    high.FillTransparency = loottrans
                end
            end

            lootespcon = lootfolder.ChildAdded:Connect(function(l)
                if l and not l:FindFirstChildOfClass("Highlight") then
                    local high = Instance.new("Highlight")

                    high.Parent = l
                    high.Adornee = l
                    high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    high.OutlineColor = lootcolor
                    high.OutlineTransparency = loottrans
                    high.FillColor = lootcolor
                    high.FillTransparency = loottrans
                end
            end)
        else
            for _,l in lootfolder:GetChildren() do
                if l and l:FindFirstChildOfClass("Highlight") then
                    l:FindFirstChildOfClass("Highlight").Enabled = false
                end
            end

            if lootespcon then
                lootespcon:Disconnect()
                lootespcon = nil
            end
        end
    end
})
objectvisuals:AddLabel('loot color'):AddColorPicker('lootcolor',{
    Title = "loot color",
    Default =  lootcolor,
    Callback = function(c)
        lootcolor = c

        for _,v in lootfolder:GetChildren() do
            if v and v:FindFirstChildOfClass("Highlight") then
                v:FindFirstChildOfClass("Highlight").FillColor = lootcolor
                v:FindFirstChildOfClass("Highlight").OutlineColor = lootcolor
            end
        end
    end
})
objectvisuals:AddSlider('lootesptrans',{
    Min = 0,
    Max = 1,
    Rounding = 2,
    Default = loottrans,
    Compact = true,
    Text = "loot transparency",
    Callback = function(v) 
        loottrans = v

        for _,v in lootfolder:GetChildren() do
            if v and v:FindFirstChildOfClass("Highlight") then
                v:FindFirstChildOfClass("Highlight").FillTransparency = loottrans
                v:FindFirstChildOfClass("Highlight").OutlineTransparency = loottrans
            end
        end
    end
})

objectvisuals:AddDivider()

objectvisuals:AddToggle('ammoesp',{
    Default = false,
    Text = "ammo esp",
    Callback = function(v)
        if v then
            for _,a in ammofolder:GetChildren() do
                if a and a:FindFirstChildOfClass("Highlight") then
                    a:FindFirstChildOfClass("Highlight").Enabled = true
                end

                if a and not a:FindFirstChildOfClass("Highlight") then
                    local high = Instance.new("Highlight")

                    high.Parent = a
                    high.Adornee = a
                    high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    high.OutlineColor = ammocolor
                    high.OutlineTransparency = ammotrans
                    high.FillColor = ammocolor
                    high.FillTransparency = ammotrans
                end
            end

            ammoespcon = ammofolder.ChildAdded:Connect(function(a)
                if a and not a:FindFirstChildOfClass("Highlight") then
                    local high = Instance.new("Highlight")

                    high.Parent = a
                    high.Adornee = a
                    high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    high.OutlineColor = ammocolor
                    high.OutlineTransparency = ammotrans
                    high.FillColor = ammocolor
                    high.FillTransparency = ammotrans
                end
            end)
        else
            for _,a in ammofolder:GetChildren() do
                if a and a:FindFirstChildOfClass("Highlight") then
                    a:FindFirstChildOfClass("Highlight").Enabled = false
                end
            end

            if ammoespcon then
                ammoespcon:Disconnect()
                ammoespcon = nil
            end
        end
    end
})
objectvisuals:AddLabel('ammo color'):AddColorPicker('ammocolor',{
    Title = "ammo color",
    Default =  ammocolor,
    Callback = function(c)
        ammocolor = c

        for _,v in ammofolder:GetChildren() do
            if v and v:FindFirstChildOfClass("Highlight") then
                v:FindFirstChildOfClass("Highlight").FillColor = ammocolor
                v:FindFirstChildOfClass("Highlight").OutlineColor = ammocolor
            end
        end
    end
})
objectvisuals:AddSlider('ammoesptrans',{
    Min = 0,
    Max = 1,
    Rounding = 2,
    Default = ammotrans,
    Compact = true,
    Text = "ammo transparency",
    Callback = function(v) 
        ammotrans = v

        for _,v in ammofolder:GetChildren() do
            if v and v:FindFirstChildOfClass("Highlight") then
                v:FindFirstChildOfClass("Highlight").FillTransparency = ammotrans
                v:FindFirstChildOfClass("Highlight").OutlineTransparency = ammotrans
            end
        end
    end
})

objectvisuals:AddDivider()

objectvisuals:AddToggle('vehicleesp',{
    Default = false,
    Text = "vehicle esp",
    Callback = function(v)
        if v then
            for _,c in vehiclefolder:GetChildren() do
                if c and c:FindFirstChildOfClass("Highlight") then
                    c:FindFirstChildOfClass("Highlight").Enabled = true
                end

                if c and not c:FindFirstChildOfClass("Highlight") then
                    local high = Instance.new("Highlight")

                    high.Parent = c
                    high.Adornee = c
                    high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    high.OutlineColor = vehiclecolor
                    high.OutlineTransparency = vehicletrans
                    high.FillColor = vehiclecolor
                    high.FillTransparency = vehicletrans
                end
            end

            vehicleespcon = vehiclefolder.ChildAdded:Connect(function(c)
                if c and not c:FindFirstChildOfClass("Highlight") then
                    local high = Instance.new("Highlight")

                    high.Parent = c
                    high.Adornee = c
                    high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    high.OutlineColor = vehiclecolor
                    high.OutlineTransparency = vehicletrans
                    high.FillColor = vehiclecolor
                    high.FillTransparency = vehicletrans
                end
            end)
        else
            for _,c in vehiclefolder:GetChildren() do
                if c and c:FindFirstChildOfClass("Highlight") then
                    c:FindFirstChildOfClass("Highlight").Enabled = false
                end
            end

            if vehicleespcon then
                vehicleespcon:Disconnect()
                vehicleespcon = nil
            end
        end
    end
})
objectvisuals:AddLabel('vehicle color'):AddColorPicker('vehiclecolor',{
    Title = "vehicle color",
    Default =  vehiclecolor,
    Callback = function(c)
        vehiclecolor = c

        for _,v in vehiclefolder:GetChildren() do
            if v and v:FindFirstChildOfClass("Highlight") then
                v:FindFirstChildOfClass("Highlight").FillColor = vehiclecolor
                v:FindFirstChildOfClass("Highlight").OutlineColor = vehiclecolor
            end
        end
    end
})
objectvisuals:AddSlider('vehicleesptrans',{
    Min = 0,
    Max = 1,
    Rounding = 2,
    Default = vehicletrans,
    Compact = true,
    Text = "vehicle transparency",
    Callback = function(v) 
        vehicletrans = v

        for _,v in vehiclefolder:GetChildren() do
            if v and v:FindFirstChildOfClass("Highlight") then
                v:FindFirstChildOfClass("Highlight").FillTransparency = vehicletrans
                v:FindFirstChildOfClass("Highlight").OutlineTransparency = vehicletrans
            end
        end
    end
})

do
    worldvisuals:AddToggle('lighthingoverride',{
        Default = false,
        Text = "override lighting",
        Callback = function(v)
            if v then
                lightingcon = runserv.Heartbeat:Connect(function()
                    lighting.Ambient = newlighting.Ambient
                    lighting.OutdoorAmbient = newlighting.OutdoorAmbient
                    lighting.Brightness = newlighting.Brightness
                    lighting.ClockTime = newlighting.ClockTime
                    lighting.FogColor = newlighting.FogColor
                    lighting.FogStart = newlighting.FogStart
                    lighting.FogEnd = newlighting.FogEnd
                    lighting.GlobalShadows = newlighting.GlobalShadows
                    lighting.ColorShift_Top = newlighting.ColorShift_Top
                    lighting.ColorShift_Bottom = newlighting.ColorShift_Bottom
                    lighting.EnvironmentDiffuseScale = newlighting.EnvironmentDiffuseScale
                    lighting.EnvironmentSpecularScale = newlighting.EnvironmentSpecularScale
                    lighting.ShadowSoftness = newlighting.ShadowSoftness
                end)
            else
                if lightingcon then
                    lightingcon:Disconnect()
                    lightingcon = nil
                end

                lighting.Ambient = oldlighting.Ambient
                lighting.OutdoorAmbient = oldlighting.OutdoorAmbient
                lighting.Brightness = oldlighting.Brightness
                lighting.ClockTime = oldlighting.ClockTime
                lighting.FogColor = oldlighting.FogColor
                lighting.FogStart = oldlighting.FogStart
                lighting.FogEnd = oldlighting.FogEnd
                lighting.GlobalShadows = oldlighting.GlobalShadows
                lighting.ColorShift_Top = oldlighting.ColorShift_Top
                lighting.ColorShift_Bottom = oldlighting.ColorShift_Bottom
                lighting.EnvironmentDiffuseScale = oldlighting.EnvironmentDiffuseScale
                lighting.EnvironmentSpecularScale = oldlighting.EnvironmentSpecularScale
                lighting.ShadowSoftness = oldlighting.ShadowSoftness
            end
        end
    })

    worldvisuals:AddDivider()

    worldvisuals:AddLabel('Ambient'):AddColorPicker('Ambient',{
        Title = "Ambient",
        Default = oldlighting.Ambient,
        Callback = function(v)
            newlighting.Ambient = v
        end
    })

    worldvisuals:AddLabel('OutdoorAmbient'):AddColorPicker('OutdoorAmbient',{
        Title = "OutdoorAmbient",
        Default =  oldlighting.OutdoorAmbient,
        Callback = function(v)
            newlighting.OutdoorAmbient = v
        end
    })

    worldvisuals:AddSlider('Brightness',{
        Min = 0,
        Max = 10,
        Rounding = 1,
        Default = oldlighting.Brightness,
        Compact = true,
        Text = "Brightness",
        Callback = function(v) 
            newlighting.Brightness = v
        end
    })

    worldvisuals:AddSlider('ClockTime',{
        Min = 0,
        Max = 24,
        Rounding = 1,
        Default = oldlighting.ClockTime,
        Compact = true,
        Text = "ClockTime",
        Callback = function(v) 
            newlighting.ClockTime = v
        end
    })

    worldvisuals:AddLabel('FogColor'):AddColorPicker('FogColor',{
        Title = "FogColor",
        Default =  oldlighting.FogColor,
        Callback = function(v)
            newlighting.FogColor = v
        end
    })

    worldvisuals:AddSlider('FogStart',{ -- game uses culling so doesnt rlly make a difference
        Min = 0,
        Max = 9999,
        Rounding = 0,
        Default = oldlighting.FogStart,
        Compact = true,
        Text = "FogStart",
        Callback = function(v) 
            newlighting.FogStart = v
        end
    })

    worldvisuals:AddSlider('FogEnd',{
        Min = 0,
        Max = 9999,
        Rounding = 0,
        Default = oldlighting.FogEnd,
        Compact = true,
        Text = "FogEnd",
        Callback = function(v) 
            newlighting.FogEnd = v
        end
    })

    worldvisuals:AddToggle('GlobalShadows',{
        Default = oldlighting.GlobalShadows,
        Text = "GlobalShadows",
        Callback = function(v)
            newlighting.GlobalShadows = v
        end
    })

    worldvisuals:AddLabel('ColorShift_Top'):AddColorPicker('ColorShift_Top',{
        Title = "ColorShift_Top",
        Default = oldlighting.ColorShift_Top,
        Callback = function(v)
            newlighting.ColorShift_Top = v
        end
    })

    worldvisuals:AddLabel('ColorShift_Bottom'):AddColorPicker('ColorShift_Bottom',{
        Title = "ColorShift_Bottom",
        Default =  oldlighting.ColorShift_Bottom,
        Callback = function(v)
            newlighting.ColorShift_Bottom = v
        end
    })

    worldvisuals:AddSlider('EnvironmentDiffuseScale',{
        Min = 0,
        Max = 1,
        Rounding = 1,
        Default = oldlighting.EnvironmentDiffuseScale,
        Compact = true,
        Text = "EnvironmentDiffuseScale",
        Callback = function(v) 
            newlighting.EnvironmentDiffuseScale = v
        end
    })

    worldvisuals:AddSlider('EnvironmentSpecularScale',{
        Min = 0,
        Max = 1,
        Rounding = 1,
        Default = oldlighting.EnvironmentSpecularScale,
        Compact = true,
        Text = "EnvironmentSpecularScale",
        Callback = function(v) 
            newlighting.EnvironmentSpecularScale = v
        end
    })

    worldvisuals:AddSlider('ShadowSoftness',{
        Min = 0,
        Max = 1,
        Rounding = 1,
        Default = oldlighting.ShadowSoftness,
        Compact = true,
        Text = "ShadowSoftness",
        Callback = function(v) 
            newlighting.ShadowSoftness = v
        end
    })

    worldvisuals:AddDivider()

    lightingreset = worldvisuals:AddButton({
        Text = "reset",
        Func = function()
            options.Ambient:SetValue(oldlighting.Ambient)
            options.OutdoorAmbient:SetValue(oldlighting.OutdoorAmbient)
            options.Brightness:SetValue(oldlighting.Brightness)
            options.ClockTime:SetValue(oldlighting.ClockTime)
            options.FogColor:SetValue(oldlighting.FogColor)
            options.FogStart:SetValue(oldlighting.FogStart)
            options.FogEnd:SetValue(oldlighting.FogEnd)
            options.GlobalShadows:SetValue(oldlighting.GlobalShadows)
            options.ColorShift_Top:SetValue(oldlighting.ColorShift_Top)
            options.ColorShift_Bottom:SetValue(oldlighting.ColorShift_Bottom)
            options.EnvironmentDiffuseScale:SetValue(oldlighting.EnvironmentDiffuseScale)
            options.EnvironmentSpecularScale:SetValue(oldlighting.EnvironmentSpecularScale)
            options.ShadowSoftness:SetValue(oldlighting.ShadowSoftness)
        end,
        DoubleClick = false,
        Visible = true
    })
end

-- shitty cleanup method but it workie
library:OnUnload(function()
    silentaim = false

    for _,v in game:GetService("Players"):GetPlayers() do
        if v and v.Character then
            if v and v.Character and v.Character:FindFirstChildOfClass("Highlight") then
                v.Character:FindFirstChildOfClass("Highlight"):Destroy()
            end 
        end
    end

    for _,v in lootfolder:GetChildren() do
        if v and v:FindFirstChildOfClass("Highlight") then
            v:FindFirstChildOfClass("Highlight"):Destroy()
        end
    end

    for _,v in waifufolder:GetChildren() do
        if v and v:FindFirstChildOfClass("Highlight") then
            v:FindFirstChildOfClass("Highlight"):Destroy()
        end
    end

    for _,v in ammofolder:GetChildren() do
        if v and v:FindFirstChildOfClass("Highlight") then
            v:FindFirstChildOfClass("Highlight"):Destroy()
        end
    end

    for _,v in vehiclefolder:GetChildren() do
        if v and v:FindFirstChildOfClass("Highlight") then
            v:FindFirstChildOfClass("Highlight"):Destroy()
        end
    end

    if lootespcon then
        lootespcon:Disconnect()
        lootespcon = nil
    end

    if ammoespcon then
        ammoespcon:Disconnect()
        ammoespcon = nil
    end

    if vehicleespcon then
        vehicleespcon:Disconnect()
        vehicleespcon = nil
    end

    if waifuespcon then
        waifuespcon:Disconnect()
        waifuespcon = nil
    end

    if walkspeedcon then
        walkspeedcon:Disconnect()
        walkspeedcon = nil
    end

    if jumppowercon then
        jumppowercon:Disconnect()
        jumppowercon = nil
    end

    if infammocon then
        infammocon:Disconnect()
        infammocon = nil
    end

    if playerespcon then
        playerespcon:Disconnect()
        playerespcon = nil
    end

    if lightingcon then
        lightingcon:Disconnect()
        lightingcon = nil
    end

    if staffdetectorcon then
        staffdetectorcon:Disconnect()
        staffdetectorcon = nil
    end

    if meleeauracon then
        meleeauracon:Disconnect()
        meleeauracon = nil
    end

    if oldpenetration then
        for i,v in oldpenetration do
            setreadonly(i, false)
            i.PenetrationAmount = v[1]
            i.PenetrationDepth  = v[2]
            i.DamageThroughWall = v[3]
            i.IgnoreHumanoids   = v[4] 
            setreadonly(i, true)
        end
    end
    if oldrecoil then
        for i,v in oldrecoil do
            setreadonly(i, false)
            i.Recoil = v[1] 
            setreadonly(i, true)
        end
    end

    if oldammo then
        for i,v in oldammo do
            setreadonly(i, false)
            i.LimitedAmmoEnabled = v[2] 
            i.AmmoCost = v[1]
            setreadonly(i, true)
        end
    end

    if oldfirerate then
        for i,v in oldfirerate do
            setreadonly(i, false)
            i.FireRate = v[1] 
            i.MaximumFireRate = v[2]
            i.FireRateIncrement = v[3]
            i.DelayBeforeFiring = v[4]
            i.DelayAfterFiring = v[5]
            i.Auto = v[6]
            v.ChargingTime = v[7]
            v.ShotgunPumpinSpeed = v[8]
            v.LaserBeamStartupDelay = v[9]
            v.LaserBeamStopDelay = v[10]
            setreadonly(i, true)
        end
    end

    lighting.Ambient = oldlighting.Ambient
    lighting.OutdoorAmbient = oldlighting.OutdoorAmbient
    lighting.Brightness = oldlighting.Brightness
    lighting.ClockTime = oldlighting.ClockTime
    lighting.FogColor = oldlighting.FogColor
    lighting.FogStart = oldlighting.FogStart
    lighting.FogEnd = oldlighting.FogEnd
    lighting.GlobalShadows = oldlighting.GlobalShadows
    lighting.ColorShift_Top = oldlighting.ColorShift_Top
    lighting.ColorShift_Bottom = oldlighting.ColorShift_Bottom
    lighting.EnvironmentDiffuseScale = oldlighting.EnvironmentDiffuseScale
    lighting.EnvironmentSpecularScale = oldlighting.EnvironmentSpecularScale
    lighting.ShadowSoftness = oldlighting.ShadowSoftness
    
    library.Unloaded = true
end)

local configgroupbox = tabs.config:AddRightGroupbox("Misc")

configgroupbox:AddLabel("Menu Keybind"):AddKeyPicker("menukeybind", { 
    Default = "Insert", 
    NoUI = true, 
    Text = "Menu Keybind" 
})
library.ToggleKeybind = options.menukeybind

configgroupbox:AddButton("Unload", function() library:Unload() end)

thememanager:SetLibrary(library)
savemanager:SetLibrary(library)
thememanager:SetFolder("aniphobia")
savemanager:SetFolder('aniphobia')
savemanager:BuildConfigSection(tabs.config)
thememanager:ApplyToTab(tabs.config)
savemanager:LoadAutoloadConfig()
