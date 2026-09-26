local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Communication = ReplicatedStorage:WaitForChild("Communication")
local Signals = Communication:WaitForChild("ServerAndClient"):WaitForChild("Signals")
local SignalEvent = Signals:WaitForChild("SignalEvent"):WaitForChild("Event")
local SignalFunction = require(Signals:WaitForChild("SignalFunction"))
local CAM = ReplicatedStorage:WaitForChild("CAM")
local Global = CAM:WaitForChild("Global")

local Quests = require(Global:WaitForChild("Subsets"):WaitForChild("Gameplay"):WaitForChild("Quests"))
local Utility = require(Global:WaitForChild("Utility"))
local AcceptCost = require(Global.Subsets.Gameplay.Quests:WaitForChild("AcceptCost"))
local ItemRequirements = require(Global:WaitForChild("Collectibles"):WaitForChild("ItemRequirements"))
local CombatPresets = require(Global:WaitForChild("Combat_presets"))
local Items = require(Global:WaitForChild("Collectibles"):WaitForChild("Items"))
local Menum = require(Global:WaitForChild("Menum"))
local CharacterInfoProvider = require(Global:WaitForChild("Character_info_provider"))
local WorldBosses = require(CAM:WaitForChild("Client"):WaitForChild("Modules"):WaitForChild("WorldBosses"))
local SkillTreeHolder = require(Global:WaitForChild("SkillService"):WaitForChild("SkillTreeholder"))
local SkillTreeStats = require(Global.SkillService:WaitForChild("Stats"))
local CraftingDefinitions = require(Global:WaitForChild("Crafting"):WaitForChild("DefaultConfigs"))
local SkillsModule = require(Global:WaitForChild("Skills_Module"))
local ServerClientPortal = require(Global:WaitForChild("ServerClientPortal"))
local SkillController = require(CAM:WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("Skill_Controller"))
local BlockingModule = require(ReplicatedStorage:WaitForChild("Skills"):WaitForChild("Misc"):WaitForChild("Blocking"))

local SkillsProvider = CAM:WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("Skills_Provider")
local CurrentPower = SkillsProvider:WaitForChild("CurPower")
local Automation = {}
Automation.GetCounter = require(ReplicatedStorage.CAM.Global.Subsets.Gameplay.StatsFetch.Functions.SkillFlags.GetCounter).GetCounter
Automation.ManageCooldown = require(Global.Subsets.Gameplay:WaitForChild("manage_cd"))
Automation.DashHandler = require(CAM.Client.Modules.GamePlay:WaitForChild("Dash_Handler"))
Automation.UserInputService = game:GetService("UserInputService")
Automation.lanternShowSerial = 0
Automation.lanternLastShow = nil
Automation.lanternResponseSerial = 0
Automation.lanternLastResponse = nil

require(Signals:WaitForChild("SignalEvent")):Connect(function(signalName, payload)
	if signalName ~= "SimonSays" or type(payload) ~= "table" then
		return
	end

	if payload.Action == "Show" and type(payload.Plates) == "table" then
		local plates = {}

		for index, plateIndex in ipairs(payload.Plates) do
			if type(plateIndex) == "number" then
				plates[index] = plateIndex
			end
		end

		if #plates > 0 then
			Automation.lanternShowSerial += 1
			Automation.lanternLastShow = {
				Serial = Automation.lanternShowSerial,
				Plates = plates,
				Lead = tonumber(payload.Lead) or 0,
				Step = tonumber(payload.Step) or 0.5,
				ReceivedAt = os.clock(),
			}
		end
	end

	if payload.Action == "Step" or payload.Action == "Fail" or payload.Action == "Win" then
		Automation.lanternResponseSerial += 1
		Automation.lanternLastResponse = {
			Serial = Automation.lanternResponseSerial,
			Action = payload.Action,
			Plate = payload.Plate,
			ReceivedAt = os.clock(),
		}

		if payload.Action == "Fail" then
			Automation.lanternLastShow = nil
		end
	end
end)

Automation.flyEnabled = false
Automation.flySpeed = 80
Automation.manualNoclipEnabled = false
Automation.speedEnabled = false
Automation.walkSpeed = 50
Automation.highJumpEnabled = false
Automation.jumpPower = 100
Automation.noAttackSlowdownEnabled = false
Automation.noDashCooldownEnabled = false
Automation.infiniteStaminaEnabled = false
Automation.instantKillEnabled = false
Automation.instantKillThreshold = 10
Automation.lastMovementHumanoid = nil
Automation.lastMovementState = nil
Automation.lastInstantKillScan = 0
Automation.autoDungeonEnabled = false
Automation.autoDungeonGeneration = 0
Automation.autoPickDungeonRewards = false
Automation.autoDungeonReady = false
Automation.dungeonUiGeneration = 0
Automation.dungeonRewardFocus = "Survival"
Automation.lastDungeonChoiceClick = -math.huge
Automation.lastDungeonReadyClick = -math.huge

local selectedQuestKey
local farmEnabled = false
local farmGeneration = 0
local selectedMobName
local mobFarmEnabled = false
local mobFarmGeneration = 0
local currentCombatTarget
local npcAttackStates = setmetatable({}, {__mode = "k"})
local blockingEnabled = false
local combatCombo = 1
local lastCombatAttack = 0
local nextCombatAttack = 0
local combatLeadFactor = 0.92
Automation.autoAttackMode = "Default"
local farmPositionType = "Behind"
local farmOffsetDistance = 6
local farmTweenSpeed = 500
local activePositionTween
local autoClaimSoulsEnabled = true
local autoParryEnabled = true
local lastAutoParry = -math.huge
local autoParryCooldown = 1
local autoParryHoldTime = 0.22
local antiHitEnabled = true
local autoChestEnabled = false
local autoChestGeneration = 0
local selectedBossName
local autoBossEnabled = false
local autoBossGeneration = 0
local autoSafeEnabled = false
local autoSafeGeneration = 0
local autoSkillTreeEnabled = false
local unlockSkillsFirst = false
local selectedSkillTreeNodes = {}
local autoCraftEnabled = false
local selectedCraftRecipes = {}
local autoSkillsEnabled = false
local selectedAutoSkills = {}
local selectedWeaponName
local autoPotionEnabled = false
local selectedPotionName = "Health Potion"
local potionHealthPercent = 40
local potionInUse = false
local noStunEnabled = false
local noRagdollEnabled = false
local selectedTeleportZone
local autoFishEnabled = false
local autoBuyBaitEnabled = false
local selectedFishingBait = "None"
local fishingPortal
local fishingBiteSequence = 0
local autoBreathingEnabled = false
local autoBreathingGeneration = 0
local selectedBreathingName
Automation.autoDroppedLootEnabled = false
Automation.autoDroppedLootGeneration = 0
local safeRetreatActive = false
local safeReturnCFrame
local safeRetreatDirection
local safeDistance = 300
local safeHealthThreshold = 1
local safeHealthThresholdCustomized = false
local displayedQuestKeys = {}
local isQuestFarmable
local questDefinitions = {}
local staticRegionPositions = {
	["Windy Peak"] = Vector3.new(-456, 1241, -932),
	["Bamboo Grove"] = Vector3.new(422, 1128, -915),
	["Mistfall Harbor"] = Vector3.new(140.73, 873.5, 728.215),
	["Hidden Mist Village"] = Vector3.new(1651.024, 607.3, -124),
	["Butterfly Estate"] = Vector3.new(-1771.965, 311.254, -110.905),
	["Iceveil Valley"] = Vector3.new(-192.6, 1348.982, -2598.405),
	["Final Selection Plains"] = Vector3.new(-2555.054, 275, 16.436),
	["Verdant Cliffs"] = Vector3.new(1774.963, 1414, -425.009),
	["Stone Sanctuary"] = Vector3.new(2564.096, 1800, -590.007),
	["Forgotten Ruins"] = Vector3.new(-953.97, 1200, 945.479),
}

local staticQuestCatalog = {
	["I will clear out his guards(Lv 40)"] = {Region = "Bamboo Grove", OfferNpc = "Wagwan", LogCompletion = false, Requirements = {Level = 40}},
	["I will take care of Hoyuzo(Lv 50)"] = {Region = "Bamboo Grove", OfferNpc = "Wagwan", LogCompletion = false, Requirements = {Level = 50}},
	["Ill bring him the notes"] = {Region = "Windy Peak", OfferNpc = "Kazu", LogCompletion = true},
	["Ill clear out his subordinates(Lv 26)"] = {Region = "Bamboo Grove", OfferNpc = "Chaka", LogCompletion = false, Requirements = {Level = 26}},
	["Ill deal with Kaiden(Lv 34)"] = {Region = "Bamboo Grove", OfferNpc = "Chaka", LogCompletion = false, Requirements = {Level = 34}},
	["Ill deliver the package"] = {Region = "Windy Peak", OfferNpc = "MoldySugar", LogCompletion = true},
	["Ill deliver the supply box(Lv 70)"] = {Region = "Mistfall Harbor", OfferNpc = "Niko", LogCompletion = false, Requirements = {Level = 70}},
	["Ill drive back the frost(Lv 105)"] = {Region = "Iceveil Valley", OfferNpc = "Demon Slayer Mitsu", LogCompletion = false, Requirements = {Level = 105}},
	["Ill drive the bears back(Lv 10)"] = {Region = "Bamboo Grove", OfferNpc = "Tom", LogCompletion = false, Requirements = {Level = 10}},
	["Ill drive them off(Lv 47)"] = {Region = "Mistfall Harbor", OfferNpc = "Rin", LogCompletion = false, Requirements = {Level = 47}},
	["Ill fell the Mother Bear(Lv 18)"] = {Region = "Bamboo Grove", OfferNpc = "Tom", LogCompletion = false, Requirements = {Level = 18}},
	["Ill find the coins(Lv 21)"] = {Region = "Bamboo Grove", OfferNpc = "Liv", LogCompletion = true, Requirements = {Level = 21}},
	["Ill find the forge(Lv 65)"] = {Region = "Hidden Mist Village", OfferNpc = "Blacksmith Togane", LogCompletion = true, Requirements = {Level = 65}},
	["Ill find the jewelry box(Lv 45)"] = {Region = "Mistfall Harbor", OfferNpc = "Ginzo", LogCompletion = true, Requirements = {Level = 45}},
	["Ill find the pages"] = {Region = "Windy Peak", OfferNpc = "Kona", LogCompletion = false},
	["Ill find the permit stamp(Lv 45)"] = {Region = "Mistfall Harbor", OfferNpc = "Sofen", LogCompletion = true, Requirements = {Level = 45}},
	["Ill get this letter delivered"] = {Region = "Windy Peak", OfferNpc = "Noote", LogCompletion = true, ConsumeItemOnAccept = "Suspicious Note"},
	["Ill help clear them out"] = {Region = "Windy Peak", OfferNpc = "Kazu", LogCompletion = false},
	["Ill help you defeat them(Lv 90)"] = {Region = "Iceveil Valley", OfferNpc = "Wounded Slayer Tomoi", LogCompletion = false, Requirements = {Level = 90, Race = {"Slayer", "Hybrid"}}},
	["Ill look for it(Lv 10)"] = {Region = "Bamboo Grove", OfferNpc = "Betty", LogCompletion = true, Requirements = {Level = 10}},
	["Ill look for the penny(Lv 14)"] = {Region = "Bamboo Grove", OfferNpc = "Liv", LogCompletion = true, Requirements = {Level = 14}},
	["Ill look for your blade(Lv 75)"] = {Region = "Butterfly Estate", OfferNpc = "Ren", LogCompletion = true, Requirements = {Level = 75}},
	["Ill put out the blaze(Lv 115)"] = {Region = "Iceveil Valley", OfferNpc = "Demon Slayer Mitsu", LogCompletion = false, Requirements = {Level = 115}},
	["Ill restock the pantry(Lv 10)"] = {Region = "Windy Peak", OfferNpc = "Lucy", LogCompletion = false, Requirements = {Level = 10}},
	["Ill take 3 bandits"] = {Region = "Windy Peak", OfferNpc = "Krue", LogCompletion = false},
	["Ill take the bandit boss(Lv 7)"] = {Region = "Windy Peak", OfferNpc = "Krue", LogCompletion = false, Requirements = {Level = 7}},
	["Theyre not welcome here(Lv 90)"] = {Region = "Iceveil Valley", OfferNpc = "Demon Delroy", LogCompletion = false, Requirements = {Level = 90, Race = {"Demon", "Hybrid"}}},
}

local staticMobCatalog = {
	["Bear Cub"] = {Region = "Bamboo Grove", Position = Vector3.new(540.5, 1121, -1023.5)},
	["Hoyuzo Subordinate"] = {Region = "Bamboo Grove"},
	["Hoyuzo"] = {Region = "Bamboo Grove"},
	["Kaiden Subordinate"] = {Region = "Bamboo Grove"},
	["Kaiden"] = {Region = "Bamboo Grove"},
	["Mother Bear"] = {Region = "Bamboo Grove", Position = Vector3.new(540.5, 1121, -1023.5)},
	["Greater Demon"] = {Region = "Butterfly Estate", Position = Vector3.new(-400.699, 287.24, 512.891)},
	["Lesser Demon"] = {Region = "Butterfly Estate", Position = Vector3.new(-715.64, 219.39, 456.22)},
	["Fujiko"] = {Region = "Final Selection Plains"},
	["Mizunoe Demon Slayer"] = {Region = "Final Selection Plains", Position = Vector3.new(-1898.827, 29.032, 487.142)},
	["Fire Profound Demon"] = {Region = "Iceveil Valley", Position = Vector3.new(-1171.125, 1382.074, -2443.031)},
	["High Demon"] = {Region = "Iceveil Valley", Position = Vector3.new(518.066, 1222.043, -1785.63)},
	["Ice Profound Demon"] = {Region = "Iceveil Valley", Position = Vector3.new(-1076.229, 1380.5, -2598.538)},
	["Kanoe Demon Slayer"] = {Region = "Iceveil Valley", Position = Vector3.new(359.65, 1350, -2297.082)},
	["Beast Born Demon"] = {Region = "Mistfall Harbor"},
	["Blood Hounded Demon"] = {Region = "Mistfall Harbor", Position = Vector3.new(700.316, 823.5, 1027.131)},
	["Mizunoto"] = {Region = "Mistfall Harbor", Position = Vector3.new(-887.885, 964, -25.963)},
	["Bandit"] = {Region = "Windy Peak", Position = Vector3.new(-287, 1223, -1107)},
	["Spy"] = {Region = "Windy Peak", Position = Vector3.new(-687, 1260.5, -1103)},
	["Zuko"] = {Region = "Windy Peak", Position = Vector3.new(-287, 1223, -1107)},
}
local staticNamedNpcPositions = {
	["MoldySugar"] = Vector3.new(-701.752869, 1243.34021, -982.68335),
	["Elara"] = Vector3.new(427.816, 941.003, 507.446),
	["Noote"] = Vector3.new(-515.546509, 1243.19995, -1251.23865),
	["Liv"] = Vector3.new(657.363281, 1018.70026, 139.748718),
	["Kazu"] = Vector3.new(-626, 1242.5, -1138),
	["Chaka"] = Vector3.new(471, 1146, -1260),
	["Lamplighter Isamu"] = Vector3.new(1082.206, 1425.703, -749.032),
}

staticQuestCatalog["Ill walk the order"] = {
	Region = "Misc",
	OfferNpc = "Lamplighter Isamu",
	LogCompletion = true,
	Position = Vector3.new(1079, 1422, -781),
}

local function getPlayerData()
	return Utility.GetData(LocalPlayer)
end

local function getCharacter()
	local character = LocalPlayer.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then
		return nil
	end

	return character, humanoid, rootPart
end

local function findHealthTextLabel()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return nil
	end

	for _, descendant in ipairs(playerGui:GetDescendants()) do
		if descendant:IsA("TextLabel") and descendant.Name == "TextEffectholder" then
			local ancestor = descendant.Parent
			while ancestor and ancestor ~= playerGui do
				if ancestor.Name == "Health" then
					return descendant
				end
				ancestor = ancestor.Parent
			end
		end
	end

	return nil
end

local function getHudDisplayedHealth()
	local healthLabel = findHealthTextLabel()

	if not healthLabel then
		return nil, nil, nil
	end

	local currentText, maximumText = healthLabel.Text:match("^%s*([%d%.]+)%s*/%s*([%d%.]+)%s*$")
	local currentHealth = tonumber(currentText)
	local maximumHealth = tonumber(maximumText)

	if currentHealth and maximumHealth and maximumHealth > 0 then
		return currentHealth, maximumHealth, healthLabel
	end

	return nil, nil, healthLabel
end

local function getDisplayedHealth()
	local currentHealth, maximumHealth, healthLabel = getHudDisplayedHealth()

	if currentHealth and maximumHealth then
		return currentHealth, maximumHealth, healthLabel
	end

	local _, humanoid = getCharacter()
	if humanoid then
		return math.min(humanoid.Health, humanoid.MaxHealth), humanoid.MaxHealth, nil
	end

	return nil, nil, nil
end
local function refreshQuestDefinitions()
	for questKey, definition in pairs(Quests.Holder) do
		if type(questKey) == "string" and type(definition) == "table" and typeof(definition.QuestInstance) == "Instance" then
			questDefinitions[questKey] = definition
		end
	end
end

local function getQuestState(questKey)
	local success, state = pcall(Quests.GetPlayerQuestState, LocalPlayer, questKey)
	if success then
		return state
	end
	return "None"
end

local function canAffordQuest(definition)
	local data = getPlayerData()
	if not data then
		return false
	end

	if type(definition.WenCostOnAccept) == "number" then
		local wen = data:FindFirstChild("Wen")
		if not wen or wen.Value < definition.WenCostOnAccept then
			return false
		end
	end

	if definition.ItemCostOnAccept ~= nil then
		local success, canAfford = pcall(AcceptCost.Check, data, definition.ItemCostOnAccept)
		if not success or canAfford ~= true then
			return false
		end
	end

	return true
end

local function canTakeQuest(questKey)
	local definition = questDefinitions[questKey] or Quests.Holder[questKey]
	if not definition or not canAffordQuest(definition) then
		return false
	end

	local success, canAdd = pcall(Quests.CanAddQuest, LocalPlayer, questKey)
	return success and canAdd == true
end

local function isQuestCatalogEligible(questKey)
	local definition = questDefinitions[questKey] or Quests.Holder[questKey]
	local catalogEntry = staticQuestCatalog[questKey]
	local data = getPlayerData()

	if not data then
		return false
	end

	if definition then
		if not canAffordQuest(definition) then
			return false
		end

		if definition.LogCompletion == true and getQuestState(questKey) == "Done" then
			return false
		end

		if definition.Requirements ~= nil and ItemRequirements.Passes(data, definition.Requirements) ~= true then
			return false
		end

		if isQuestFarmable and not isQuestFarmable(questKey) then
			return false
		end

		return true
	end

	if not catalogEntry then
		return false
	end

	if catalogEntry.LogCompletion == true then
		local quests = data:FindFirstChild("Quests")
		local completed = quests and quests:FindFirstChild("Completed")
		if completed and completed:FindFirstChild(questKey) then
			return false
		end
	end

	if catalogEntry.Requirements ~= nil and ItemRequirements.Passes(data, catalogEntry.Requirements) ~= true then
		return false
	end

	if type(catalogEntry.ConsumeItemOnAccept) == "string" then
		local inventory = data:FindFirstChild("Inventory")
		inventory = inventory and inventory:FindFirstChild("Inventory")
		local quests = data:FindFirstChild("Quests")
		local holder = quests and quests:FindFirstChild("Holder")
		local activeQuest = false

		if holder then
			for _, quest in ipairs(holder:GetChildren()) do
				local questString = quest:FindFirstChild("QuestString")
				if questString and questString.Value == questKey then
					activeQuest = true
					break
				end
			end
		end

		if not activeQuest and (not inventory or not inventory:FindFirstChild(catalogEntry.ConsumeItemOnAccept)) then
			return false
		end
	end

	return true
end

local function getAvailableQuestKeys()
	local available = {}
	local seen = {}

	for questKey in pairs(staticQuestCatalog) do
		if isQuestCatalogEligible(questKey) then
			seen[questKey] = true
			table.insert(available, questKey)
		end
	end

	for questKey in pairs(questDefinitions) do
		if not seen[questKey] and isQuestCatalogEligible(questKey) then
			seen[questKey] = true
			table.insert(available, questKey)
		end
	end

	table.sort(available, function(left, right)
		local leftDefinition = questDefinitions[left]
		local rightDefinition = questDefinitions[right]
		local leftCatalog = staticQuestCatalog[left]
		local rightCatalog = staticQuestCatalog[right]
		local leftRequirements = leftDefinition and leftDefinition.Requirements or leftCatalog and leftCatalog.Requirements
		local rightRequirements = rightDefinition and rightDefinition.Requirements or rightCatalog and rightCatalog.Requirements
		local leftLevel = leftRequirements and tonumber(leftRequirements.Level) or 0
		local rightLevel = rightRequirements and tonumber(rightRequirements.Level) or 0

		if leftLevel == rightLevel then
			return left:lower() < right:lower()
		end

		return leftLevel < rightLevel
	end)

	return available
end

local function getActiveQuest(questKey)
	local data = getPlayerData()
	local definition = questDefinitions[questKey] or Quests.Holder[questKey]
	if not data or not definition or not definition.QuestInstance then
		return nil
	end

	local quests = data:FindFirstChild("Quests")
	local holder = quests and quests:FindFirstChild("Holder")
	if not holder then
		return nil
	end

	local directQuest = holder:FindFirstChild(definition.QuestInstance.Name)
	if directQuest then
		return directQuest
	end

	for _, quest in ipairs(holder:GetChildren()) do
		local questString = quest:FindFirstChild("QuestString")
		if questString and questString.Value == questKey then
			return quest
		end
	end

	return nil
end
local function getQuestKeyFromInstance(quest)
	if not quest then
		return nil
	end

	local questString = quest:FindFirstChild("QuestString")
	if questString and questString:IsA("StringValue") and questString.Value ~= "" then
		return questString.Value
	end

	for questKey, definition in pairs(questDefinitions) do
		if definition.QuestInstance and definition.QuestInstance.Name == quest.Name then
			return questKey
		end
	end

	return nil
end

local function cancelOtherActiveQuests(keepQuestKey)
	local data = getPlayerData()
	local quests = data and data:FindFirstChild("Quests")
	local holder = quests and quests:FindFirstChild("Holder")
	if not holder then
		return
	end

	for _, quest in ipairs(holder:GetChildren()) do
		local questKey = getQuestKeyFromInstance(quest)
		if questKey ~= keepQuestKey then
			SignalEvent:FireServer("RemoveQuest", quest.Name)

			local deadline = os.clock() + 2
			while quest.Parent and os.clock() < deadline do
				task.wait(0.05)
			end
		end
	end
end

local function getPendingQuestTask(activeQuest)
	local tasks = activeQuest and activeQuest:FindFirstChild("Tasks")
	if not tasks then
		return nil
	end

	for _, questTask in ipairs(tasks:GetChildren()) do
		local value = questTask:FindFirstChild("Value")
		local maximum = questTask:FindFirstChild("Max")
		if value and maximum and value.Value < maximum.Value and Quests.TaskNeedMet(questTask) then
			return questTask
		end
	end

	return nil
end

local function getQuestPosition(questKey, questTask)
	local definition = questDefinitions[questKey] or Quests.Holder[questKey]
	if not definition then
		return nil
	end

	if type(definition.Markers) == "table" and questTask then
		local marker = definition.Markers[questTask.Name]
		if type(marker) == "table" and typeof(marker.Position) == "Vector3" then
			return marker.Position
		end
	end

	if typeof(definition.Position) == "Vector3" then
		return definition.Position
	end

	return nil
end

local function normalizeNpcIdentifier(value)
	if type(value) ~= "string" then
		return ""
	end

	return value:lower():gsub("[^%w]", "")
end

local function getNpcMatchScore(npcCode, candidateName)
	local normalizedCode = normalizeNpcIdentifier(npcCode)
	local normalizedCandidate = normalizeNpcIdentifier(candidateName)

	if normalizedCode == "" or normalizedCandidate == "" then
		return 0
	end

	if normalizedCode == normalizedCandidate then
		return 10000
	end

	if normalizedCode:find(normalizedCandidate, 1, true) then
		return 6000 + #normalizedCandidate
	end

	if normalizedCandidate:find(normalizedCode, 1, true) then
		return 5500 + #normalizedCode
	end

	return 0
end

local function getNearestNpc(npcCode, questPosition)
	local character, _, rootPart = getCharacter()
	if not character or not rootPart then
		return nil
	end

	local humanoids = workspace:FindFirstChild("Humanoids")
	local regions = humanoids and humanoids:FindFirstChild("Regions")
	if not regions then
		return nil
	end

	local bestNpc
	local bestScore = 0
	local bestQuestDistance = math.huge
	local bestPlayerDistance = math.huge

	for _, instance in ipairs(regions:GetDescendants()) do
		if instance:IsA("Model") then
			local humanoid = instance:FindFirstChildOfClass("Humanoid")
			local targetRoot = instance:FindFirstChild("HumanoidRootPart")

			if humanoid and targetRoot and humanoid.Health > 0 then
				local score = 0
				local modelCode = instance:GetAttribute("NpcCode") or instance:GetAttribute("NPCCode")

				if type(modelCode) == "string" and modelCode == npcCode then
					score = 12000
				elseif (npcCode == "VillageSpy" or npcCode == "Spy")
					and (
						instance.Name == "*Civilian*"
							or instance.Name:find("VillageSpy", 1, true)
							or instance.Parent and instance.Parent.Name == "Spy"
					)
				then
					score = 11500
				else
					score = math.max(
						getNpcMatchScore(npcCode, instance.Name),
						getNpcMatchScore(npcCode, instance.Parent and instance.Parent.Name or "")
					)
				end

				if score > 0 then
					local playerDistance = (rootPart.Position - targetRoot.Position).Magnitude
					local questDistance = typeof(questPosition) == "Vector3" and (questPosition - targetRoot.Position).Magnitude or playerDistance

					if score > bestScore
						or score == bestScore and questDistance < bestQuestDistance
						or score == bestScore and questDistance == bestQuestDistance and playerDistance < bestPlayerDistance then
						bestNpc = instance
						bestScore = score
						bestQuestDistance = questDistance
						bestPlayerDistance = playerDistance
					end
				end
			end
		end
	end

	return bestNpc
end
local function getBlockingAimPosition()
	local _, _, rootPart = getCharacter()
	if not rootPart then
		return Vector3.zero
	end

	return rootPart.Position + rootPart.CFrame.LookVector * 10
end

local function hasReplicatedBlockingState()
	local values = ReplicatedStorage:FindFirstChild("Player_Service")
	values = values and values:FindFirstChild("Values")
	values = values and values:FindFirstChild(LocalPlayer.Name)
	return values and values:FindFirstChild("Blocking") ~= nil
end

local function setBlocking(enabled)
	local replicatedBlocking = hasReplicatedBlockingState()

	if enabled then
		if blockingEnabled and replicatedBlocking then
			return
		end

		blockingEnabled = true
		pcall(BlockingModule.Hold, LocalPlayer)
		SignalEvent:FireServer("server_skill_controller_signaler", "Blocking", "Hold", getBlockingAimPosition())
		return
	end

	if not blockingEnabled and not replicatedBlocking then
		return
	end

	blockingEnabled = false
	pcall(BlockingModule.UnHold, LocalPlayer)
	SignalEvent:FireServer("server_skill_controller_signaler", "Blocking", "UnHold", getBlockingAimPosition())
end
local noclipState = setmetatable({}, {__mode = "k"})
Automation.suspendNoclip = false

local function isAnyFarmModeEnabled()
	return farmEnabled or mobFarmEnabled or autoChestEnabled or autoBossEnabled or autoBreathingEnabled or Automation.autoDungeonEnabled
end

local function updateNoclip()
	local character = LocalPlayer.Character

	if not Automation.suspendNoclip and (isAnyFarmModeEnabled() or Automation.manualNoclipEnabled) and character then
		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") then
				if noclipState[descendant] == nil then
					noclipState[descendant] = descendant.CanCollide
				end
				descendant.CanCollide = false
			end
		end
		return
	end

	for part, canCollide in pairs(noclipState) do
		if part and part.Parent then
			part.CanCollide = canCollide
		end
		noclipState[part] = nil
	end
end

local function updateNoStun()
	if not noStunEnabled then
		return
	end

	local character, humanoid, rootPart = getCharacter()
	if not character or not humanoid or not rootPart then
		return
	end

	local valuesRoot = ReplicatedStorage:FindFirstChild("Player_Service")
	valuesRoot = valuesRoot and valuesRoot:FindFirstChild("Values")
	local values = valuesRoot and valuesRoot:FindFirstChild(LocalPlayer.Name)
	if not values then
		return
	end

	local stunned = values:FindFirstChild("Stun")
		or values:FindFirstChild("Strict_Stun")
		or values:FindFirstChild("CombatStun")
		or values:FindFirstChild("Root")
		or values:FindFirstChild("Rooted")
		or values:FindFirstChild("skill_stand_still")
		or rootPart:FindFirstChild("skill_stand_still")

	if stunned then
		humanoid.WalkSpeed = math.max(humanoid.WalkSpeed, 16)
		humanoid.JumpPower = math.max(humanoid.JumpPower, 50)
		humanoid.JumpHeight = math.max(humanoid.JumpHeight, 7.2)
	end
end

function Automation.getLocalStamina()
	local valuesRoot = ReplicatedStorage:FindFirstChild("Player_Service")
	valuesRoot = valuesRoot and valuesRoot:FindFirstChild("Values")
	local values = valuesRoot and valuesRoot:FindFirstChild(LocalPlayer.Name)
	return values and values:FindFirstChild("Stamina") or nil
end

function Automation.clearMovementCooldowns()
	local character = LocalPlayer.Character
	local shc = character and (character:FindFirstChild("SHC") or character:FindFirstChild("SHCS"))
	if not shc then
		return
	end

	for _, skillName in ipairs({"Dash", "Double Jump"}) do
		local success, cooldownName = pcall(Automation.ManageCooldown.filter_cd_name, LocalPlayer, skillName)
		if success and type(cooldownName) == "string" then
			local cooldown = shc:FindFirstChild(cooldownName)
			if cooldown then
				cooldown:Destroy()
			end
		end
	end
end

function Automation.hasNetworkOwnership(part)
	if not part or not part:IsA("BasePart") or part.Anchored then
		return false
	end

	local checker = rawget(getfenv(), "isnetworkowner")
	if type(checker) ~= "function" then
		return false
	end

	local success, result = pcall(checker, part)
	return success and result == true
end

function Automation.updateInstantKill()
	if not Automation.instantKillEnabled or os.clock() - Automation.lastInstantKillScan < 0.08 then
		return
	end

	Automation.lastInstantKillScan = os.clock()

	local humanoids = workspace:FindFirstChild("Humanoids")
	local regions = humanoids and humanoids:FindFirstChild("Regions")
	if not regions then
		return
	end

	for _, model in ipairs(regions:GetDescendants()) do
		if model:IsA("Model") then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local rootPart = model:FindFirstChild("HumanoidRootPart")

			if humanoid and rootPart and humanoid.Health > 0 and humanoid.MaxHealth > 0 then
				local remainingPercent = humanoid.Health / humanoid.MaxHealth * 100

				if remainingPercent <= Automation.instantKillThreshold and Automation.hasNetworkOwnership(rootPart) then
					humanoid.Health = 0
					humanoid:ChangeState(Enum.HumanoidStateType.Dead)
				end
			end
		end
	end
end

function Automation.updateMovementFeatures()
	local character, humanoid, rootPart = getCharacter()
	if not character or not humanoid or not rootPart then
		Automation.lastMovementHumanoid = nil
		Automation.lastMovementState = nil
		return
	end

	if Automation.noAttackSlowdownEnabled then
		CombatPresets.Last_Punched = -1000000
		CombatPresets.Last_Punched_Jump = -1000000
	end

	if Automation.infiniteStaminaEnabled then
		local stamina = Automation.getLocalStamina()
		if stamina and stamina:IsA("IntConstrainedValue") then
			stamina.Value = stamina.MaxValue
		elseif stamina and stamina:IsA("NumberValue") then
			local maximum = stamina:GetAttribute("Max") or stamina:GetAttribute("Maximum")
			if type(maximum) == "number" then
				stamina.Value = maximum
			end
		end
	end

	if Automation.noDashCooldownEnabled then
		Automation.clearMovementCooldowns()
	end

	if Automation.flyEnabled then
		local direction = humanoid.MoveDirection
		local vertical = 0

		if Automation.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			vertical += 1
		end

		if Automation.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
			or Automation.UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
		then
			vertical -= 1
		end

		rootPart.AssemblyLinearVelocity = Vector3.new(
			direction.X * Automation.flySpeed,
			vertical * Automation.flySpeed,
			direction.Z * Automation.flySpeed
		)
	elseif Automation.speedEnabled then
		local direction = humanoid.MoveDirection
		local velocity = rootPart.AssemblyLinearVelocity
		rootPart.AssemblyLinearVelocity = Vector3.new(
			direction.X * Automation.walkSpeed,
			velocity.Y,
			direction.Z * Automation.walkSpeed
		)
	end

	local state = humanoid:GetState()

	if Automation.highJumpEnabled
		and humanoid == Automation.lastMovementHumanoid
		and state == Enum.HumanoidStateType.Jumping
		and Automation.lastMovementState ~= Enum.HumanoidStateType.Jumping
	then
		local velocity = rootPart.AssemblyLinearVelocity
		rootPart.AssemblyLinearVelocity = Vector3.new(velocity.X, Automation.jumpPower, velocity.Z)
	end

	Automation.lastMovementHumanoid = humanoid
	Automation.lastMovementState = state
	Automation.updateInstantKill()
end
RunService.Stepped:Connect(function()
	updateNoclip()
	updateNoStun()
	Automation.updateMovementFeatures()
end)

local function canAutoParry()
	if not autoParryEnabled then
		return false
	end

	if os.clock() - lastAutoParry < autoParryCooldown then
		return false
	end

	local valuesRoot = ReplicatedStorage:FindFirstChild("Player_Service")
	valuesRoot = valuesRoot and valuesRoot:FindFirstChild("Values")
	local values = valuesRoot and valuesRoot:FindFirstChild(LocalPlayer.Name)

	if values then
		if values:FindFirstChild("Stun") or values:FindFirstChild("CombatStun") then
			return false
		end

		local damageState = values:FindFirstChild("DMG")
		local lastAttacked = damageState and damageState:GetAttribute("LastAttacked")

		if type(lastAttacked) == "number" and Utility.Tick() - lastAttacked < 1 then
			return false
		end
	end

	return true
end

local function performAutoParry()
	if not canAutoParry() then
		return false
	end

	lastAutoParry = os.clock()
	setBlocking(true)
	task.wait(autoParryHoldTime)
	setBlocking(false)

	return true
end


local function resolveCombatPreset()
	local equippedTool = CharacterInfoProvider.Get_equipped_tool(LocalPlayer)
	local equippedItem = equippedTool and Items[equippedTool.Name] or nil
	local combatName

	if equippedItem and equippedItem.CombatPreset and equippedItem.CombatPreset ~= "Combat" then
		combatName = equippedTool.Name
	else
		for _, powerName in ipairs(string.split(CurrentPower.Value, ",")) do
			local animations = ReplicatedStorage:FindFirstChild("Assets")
			animations = animations and animations:FindFirstChild("Animations")
			if animations and animations:FindFirstChild(powerName .. "_Combat_Anims") then
				combatName = powerName
				break
			end
		end

		if not combatName and equippedTool then
			if equippedItem and equippedItem.HasCombat then
				combatName = equippedTool.Name
			else
				local animations = ReplicatedStorage:FindFirstChild("Assets")
				animations = animations and animations:FindFirstChild("Animations")
				if animations and animations:FindFirstChild(equippedTool.Name .. "_Combat_Anims") then
					combatName = equippedTool.Name
				end
			end
		end
	end

	combatName = combatName or "Combat"

	local overrideName
	local preset = CombatPresets.Presets[combatName]

	if not preset and Items[combatName] then
		local item = Items[combatName]
		if item.Breathing ~= nil or item.HasCombat or item.CombatPreset ~= nil then
			overrideName = combatName
			combatName = item.CombatPreset or "Regular Katana"
			preset = CombatPresets.Presets[combatName]
		end
	end

	if not preset then
		combatName = "Combat"
		overrideName = nil
		preset = CombatPresets.Presets.Combat
	end

	return combatName, preset, overrideName
end

local function getCombatTiming(preset, combo)
	local swingDelay
	if type(preset.delay_before_swing) == "table" then
		swingDelay = preset.delay_before_swing[combo]
	end
	swingDelay = swingDelay or preset.default_before_swing or CombatPresets.Default_Swing_Wait or 0

	local hitDelay
	if type(preset.delay_before_hit) == "table" then
		hitDelay = preset.delay_before_hit[combo]
	end
	hitDelay = hitDelay or preset.default_before_hit or swingDelay

	local attackSpeed = CombatPresets.attackSpeedMult(LocalPlayer)
	local serverHitDelay = math.max((hitDelay - swingDelay) / attackSpeed, 0)

	local attackInterval
	if type(preset.customDelay) == "table" then
		attackInterval = preset.customDelay[combo]
	end
	attackInterval = attackInterval or preset.default or 0.25

	local maximumCombo = preset.Max or 5
	if combo == maximumCombo and preset.final then
		attackInterval = math.max(attackInterval, preset.final)
	end

	attackInterval = math.max(attackInterval / attackSpeed, 0.12)

	return serverHitDelay, attackInterval, swingDelay
end
local function isCombatAutomationActive(generation, mode)
	if mode == "Mob" then
		return mobFarmEnabled and mobFarmGeneration == generation
	end

	if mode == "Chest" then
		return autoChestEnabled and autoChestGeneration == generation
	end

	if mode == "Boss" then
		return autoBossEnabled and autoBossGeneration == generation
	end

	if mode == "Breathing" then
		return autoBreathingEnabled and autoBreathingGeneration == generation
	end

	if mode == "Dungeon" then
		return Automation.autoDungeonEnabled and Automation.autoDungeonGeneration == generation
	end

	return farmEnabled and farmGeneration == generation
end

local function playCombatAnimation(combatName, overrideName, combo, preset)
	local character, humanoid = getCharacter()
	if not character or not humanoid then
		return
	end

	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local animations = assets and assets:FindFirstChild("Animations")
	if not animations then
		return
	end

	local animationFolder
	if overrideName then
		animationFolder = animations:FindFirstChild(overrideName .. "_Combat_Anims")
	end
	animationFolder = animationFolder or animations:FindFirstChild(combatName .. "_Combat_Anims")
	animationFolder = animationFolder or animations:FindFirstChild("Combat_Combat_Anims")
	if not animationFolder then
		return
	end

	local animation = animationFolder:FindFirstChild("Swing_" .. combo)
	if not animation or not animation:IsA("Animation") then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		local track = animator:LoadAnimation(animation)
		track:Play()

		local animationSpeed = 1
		if type(preset.AnimSpeed) == "table" then
			animationSpeed = preset.AnimSpeed[combo] or preset.AnimSpeed.Default or 1
			animationSpeed *= CombatPresets.attackSpeedMult(LocalPlayer)
		end

		if animationSpeed ~= 1 then
			track:AdjustSpeed(animationSpeed)
		end
	end
end

local function performCombatAttack(generation, mode)
	local character = getCharacter()
	if not character then
		return nil
	end

	local combatName, preset, overrideName = resolveCombatPreset()
	if not preset then
		return nil
	end

	local attackSpeed = CombatPresets.attackSpeedMult(LocalPlayer)
	local comboResetTime = (CombatPresets.combo_duration or 1) / attackSpeed
	if os.clock() - lastCombatAttack > comboResetTime then
		combatCombo = 1
	end

	local maximumCombo = preset.Max or 5
	if combatCombo > maximumCombo then
		combatCombo = 1
	end

	local serverHitDelay, attackInterval, swingDelay = getCombatTiming(preset, combatCombo)
	local attackStartedAt = os.clock()
	local instantAttack = Automation.autoAttackMode == "Instant"

	playCombatAnimation(combatName, overrideName, combatCombo, preset)
	lastCombatAttack = attackStartedAt

	-- Keep the normal predicted recovery timestamp even in Instant mode so
	-- defensive logic still knows when the weapon would normally be recovering.
	nextCombatAttack = attackStartedAt + attackInterval * combatLeadFactor

	if not instantAttack then
		task.wait(swingDelay)
	end

	if not isCombatAutomationActive(generation, mode) or not getCharacter() then
		return nil
	end

	if currentCombatTarget and Automation.isTargetDefending(currentCombatTarget) then
		nextCombatAttack = os.clock() + 0.05
		return nil
	end

	SignalEvent:FireServer("Combat_Service", combatName, combatCombo, false, serverHitDelay, false, overrideName)

	if combatCombo >= maximumCombo then
		combatCombo = 1
	else
		combatCombo += 1
	end

	return serverHitDelay
end

local function isAttackTrack(track)
	if not track.IsPlaying or track.Priority.Value < Enum.AnimationPriority.Action.Value then
		return false
	end

	local name = track.Name:lower()

	if name:find("idle", 1, true)
		or name:find("walk", 1, true)
		or name:find("run", 1, true)
		or name:find("block", 1, true)
		or name:find("stun", 1, true)
		or name:find("hurt", 1, true)
		or name:find("hitreact", 1, true)
		or name:find("death", 1, true)
		or name:find("die", 1, true)
		or name:find("dodge", 1, true)
		or name:find("equip", 1, true)
		or name:find("unequip", 1, true)
		or name:find("charge", 1, true)
		or name:find("roar", 1, true)
		or name:find("spawn", 1, true)
	then
		return false
	end

	return name:find("attack", 1, true) ~= nil
		or name:find("swing", 1, true) ~= nil
		or name:find("slash", 1, true) ~= nil
		or name:find("strike", 1, true) ~= nil
		or name:find("punch", 1, true) ~= nil
		or name:find("kick", 1, true) ~= nil
		or name:find("m1", 1, true) ~= nil
		or name:find("m2", 1, true) ~= nil
		or name:find("combo", 1, true) ~= nil
end

local function isTargetAttacking(target)
	local now = os.clock()
	local state = npcAttackStates[target]

	if not state then
		state = {
			attackUntil = 0,
			comboValue = nil,
			comboTime = nil,
			tracks = setmetatable({}, {__mode = "k"}),
		}
		npcAttackStates[target] = state
	end

	local combo = target:FindFirstChild("Combo")
	if combo and combo:IsA("IntValue") then
		local comboTime = combo:FindFirstChild("Time")
		local currentCombo = combo.Value
		local currentTime = comboTime and comboTime:IsA("NumberValue") and comboTime.Value or 0

		if state.comboValue == nil then
			state.comboValue = currentCombo
			state.comboTime = currentTime
		elseif currentCombo ~= state.comboValue or currentTime ~= state.comboTime then
			state.comboValue = currentCombo
			state.comboTime = currentTime
			state.attackUntil = math.max(state.attackUntil, now + 0.65)
		end
	end

	local humanoid = target:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	local activeTracks = {}

	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			if isAttackTrack(track) then
				activeTracks[track] = true
				state.attackUntil = math.max(state.attackUntil, now + 0.18)

				if not state.tracks[track] then
					state.tracks[track] = true
					local length = track.Length
					local window = 0.45

					if type(length) == "number" and length > 0 then
						window = math.clamp(length * 0.55, 0.3, 0.75)
					end

					state.attackUntil = math.max(state.attackUntil, now + window)
				end
			end
		end
	end

	for track in pairs(state.tracks) do
		if not activeTracks[track] then
			state.tracks[track] = nil
		end
	end

	return now <= state.attackUntil
end

function Automation.isTargetDefending(target)
	if not target or not target.Parent then
		return false
	end

	local npcCounter = target:GetAttribute("NpcCounter")
	if npcCounter == 1 or npcCounter == 2 then
		return true
	end

	if target:FindFirstChild("NpcCounterTriggered") then
		return true
	end

	local success, values = pcall(Utility.getvaluesfolder, target)
	if not success or not values then
		return false
	end

	if values:FindFirstChild("Blocking") and not values:FindFirstChild("PierceBlock") then
		return true
	end

	local counterSuccess, counterType = pcall(Automation.GetCounter, target, values)
	if counterSuccess and (counterType == 1 or counterType == 2) then
		return true
	end

	return false
end

local function getFarmTargetCFrame(targetRoot)
	local offset

	if farmPositionType == "Above" then
		offset = CFrame.new(0, farmOffsetDistance, 0)
	elseif farmPositionType == "Behind" then
		offset = CFrame.new(0, 0, farmOffsetDistance)
	elseif farmPositionType == "Front" then
		offset = CFrame.new(0, 0, -farmOffsetDistance)
	else
		offset = CFrame.new(0, -farmOffsetDistance, 0)
	end

	local desiredPosition = (targetRoot.CFrame * offset).Position
	local upVector = Vector3.new(0, 1, 0)

	if farmPositionType == "Above" or farmPositionType == "Below" then
		upVector = Vector3.new(0, 0, -1)
	end

	return CFrame.lookAt(desiredPosition, targetRoot.Position, upVector)
end

local function moveNearTarget(target)
	local _, humanoid, rootPart = getCharacter()
	local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or not targetRoot then
		return false
	end

	local desiredCFrame = getFarmTargetCFrame(targetRoot)
	local distance = (rootPart.Position - desiredCFrame.Position).Magnitude

	if activePositionTween then
		activePositionTween:Cancel()
		activePositionTween = nil
	end

	if distance <= 1 or farmTweenSpeed <= 0 then
		rootPart.CFrame = desiredCFrame
	else
		local duration = math.clamp(distance / farmTweenSpeed, 0.02, 0.5)
		activePositionTween = TweenService:Create(rootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			CFrame = desiredCFrame,
		})
		activePositionTween:Play()
	end

	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	return true
end

local function moveAboveTarget(target)
	local _, _, rootPart = getCharacter()
	local targetRoot = target and target:FindFirstChild("HumanoidRootPart")

	if not rootPart or not targetRoot then
		return false
	end

	if activePositionTween then
		activePositionTween:Cancel()
		activePositionTween = nil
	end

	local position = targetRoot.Position + Vector3.new(0, math.max(farmOffsetDistance + 6, 10), 0)
	rootPart.CFrame = CFrame.lookAt(position, targetRoot.Position, Vector3.new(0, 0, 1))
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	return true
end

local function getWorldPosition(instance)
	if not instance then
		return nil
	end

	if instance:IsA("BasePart") then
		return instance.Position
	end

	if instance:IsA("Model") then
		local primaryPart = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
		if primaryPart then
			return primaryPart.Position
		end

		local success, pivot = pcall(instance.GetPivot, instance)
		if success then
			return pivot.Position
		end
	end

	return nil
end

local function triggerPrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return false
	end

	local globalFirePrompt = rawget(getfenv(), "fireproximityprompt")
	if type(globalFirePrompt) == "function" then
		local success = pcall(globalFirePrompt, prompt)
		if success then
			return true
		end
	end

	local success = pcall(function()
		prompt:InputHoldBegin()
		task.wait(math.max(prompt.HoldDuration, 0.05))
		prompt:InputHoldEnd()
	end)

	return success
end

local function handleIncomingAttack(target)
	if not isTargetAttacking(target) then
		return false
	end

	if autoParryEnabled then
		if performAutoParry() then
			return true
		end

		if antiHitEnabled then
			setBlocking(false)
			moveAboveTarget(target)
			task.wait(0.05)
			return true
		end

		setBlocking(false)
		task.wait(0.05)
		return true
	end

	if antiHitEnabled then
		setBlocking(false)
		moveAboveTarget(target)
		task.wait(0.05)
		return true
	end

	setBlocking(false)
	task.wait(0.05)

	return true
end

function Automation.waitCombatRecovery(target, duration, generation, mode)
	local deadline = os.clock() + math.max(duration or 0, 0)

	while os.clock() < deadline do
		if not isCombatAutomationActive(generation, mode) or safeRetreatActive then
			return false
		end

		if target and target.Parent and (autoParryEnabled or antiHitEnabled) then
			handleIncomingAttack(target)
		end

		task.wait(0.01)
	end

	return true
end

local function claimNearbySouls(originPosition)
	if not autoClaimSoulsEnabled or typeof(originPosition) ~= "Vector3" then
		return
	end

	local debree = workspace:FindFirstChild("Debree")
	if not debree then
		return
	end

	local _, _, rootPart = getCharacter()
	if not rootPart then
		return
	end

	local returnCFrame = rootPart.CFrame

	for _, instance in ipairs(debree:GetChildren()) do
		if instance.Name:lower():find("soul", 1, true) then
			local position = getWorldPosition(instance)
			if position and (position - originPosition).Magnitude <= 25 then
				rootPart.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
				rootPart.AssemblyLinearVelocity = Vector3.zero
				rootPart.AssemblyAngularVelocity = Vector3.zero

				for _, descendant in ipairs(instance:GetDescendants()) do
					if descendant:IsA("ProximityPrompt") then
						triggerPrompt(descendant)
					end
				end

				local globalFireTouch = rawget(getfenv(), "firetouchinterest")
				if type(globalFireTouch) == "function" then
					local touchPart = instance:IsA("BasePart") and instance or instance:FindFirstChildWhichIsA("BasePart", true)
					if touchPart then
						pcall(globalFireTouch, rootPart, touchPart, 0)
						pcall(globalFireTouch, rootPart, touchPart, 1)
					end
				end

				task.wait(0.12)
			end
		end
	end

	if rootPart.Parent then
		rootPart.CFrame = returnCFrame
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end
end

local function moveToQuestArea(position)
	local _, _, rootPart = getCharacter()
	if not rootPart or typeof(position) ~= "Vector3" then
		return
	end

	pcall(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, position, 3)
	local destination = position + Vector3.new(0, 4, 0)
	rootPart.CFrame = CFrame.new(destination)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	task.wait(0.35)
end

local function fightTarget(target, activeQuest, questTask, generation)
	currentCombatTarget = target
	if selectedWeaponName then
		Automation.equipSelectedWeapon()
	end
	local lastTargetPosition

	while farmEnabled and farmGeneration == generation and not safeRetreatActive and target.Parent and activeQuest.Parent and questTask.Parent do
		local humanoid = target:FindFirstChildOfClass("Humanoid")
		local targetRoot = target:FindFirstChild("HumanoidRootPart")
		local character, _, rootPart = getCharacter()

		if targetRoot then
			lastTargetPosition = targetRoot.Position
		end

		if not humanoid or humanoid.Health <= 0 or not targetRoot then
			break
		end

		if not character or not rootPart then
			setBlocking(false)
			task.wait(0.25)
			continue
		end

		if handleIncomingAttack(target) then
			continue
		end

		moveNearTarget(target)

		if Automation.isTargetDefending(target) then
			setBlocking(false)
			task.wait(0.06)
			continue
		end

		setBlocking(false)

		local instantAttack = Automation.autoAttackMode == "Instant"

		if instantAttack or os.clock() >= nextCombatAttack then
			if not instantAttack then
				task.wait(0.04)
			end

			if Automation.isTargetDefending(target) then
				nextCombatAttack = os.clock() + 0.05
				continue
			end

			if not farmEnabled or farmGeneration ~= generation then
				break
			end

			moveNearTarget(target)
			local serverHitDelay = performCombatAttack(generation, "Quest")
			if serverHitDelay and not instantAttack then
				Automation.waitCombatRecovery(target, serverHitDelay + 0.03, generation, "Quest")
			end
		end

		task.wait(instantAttack and 0.01 or 0.04)
	end

	if currentCombatTarget == target then
		currentCombatTarget = nil
	end

	setBlocking(false)

	local finalHumanoid = target:FindFirstChildOfClass("Humanoid")
	if lastTargetPosition and (not target.Parent or not finalHumanoid or finalHumanoid.Health <= 0) then
		claimNearbySouls(lastTargetPosition)
	end
end
local function findQuestGiver(questKey)
	local definition = questDefinitions[questKey] or Quests.Holder[questKey]
	local catalogEntry = staticQuestCatalog[questKey]
	local offerNpc = definition and definition.OfferNpc or catalogEntry and catalogEntry.OfferNpc
	if offerNpc == false then
		return false
	end

	if type(offerNpc) ~= "string" or offerNpc == "" then
		return nil
	end

	local _, _, rootPart = getCharacter()
	if not rootPart then
		return nil
	end

	local searchRoot = workspace:FindFirstChild("Debree")
	searchRoot = searchRoot and searchRoot:FindFirstChild("Regions") or workspace

	local nearestNpc
	local nearestDistance = math.huge

	for _, instance in ipairs(searchRoot:GetDescendants()) do
		if instance:IsA("Model") and instance.Name == offerNpc then
			local npcRoot = instance:FindFirstChild("HumanoidRootPart") or instance.PrimaryPart
			if npcRoot then
				local distance = (rootPart.Position - npcRoot.Position).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearestNpc = instance
				end
			end
		end
	end

	return nearestNpc
end

local function moveToQuestGiver(questKey)
	local questGiver = findQuestGiver(questKey)

	if questGiver == false then
		return true
	end

	if not questGiver then
		local catalogEntry = staticQuestCatalog[questKey]
		local regionPosition = catalogEntry and (
			catalogEntry.Position
				or staticNamedNpcPositions[catalogEntry.OfferNpc]
				or staticRegionPositions[catalogEntry.Region]
		)
		local _, _, rootPart = getCharacter()

		if not regionPosition or not rootPart then
			return false
		end

		pcall(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, regionPosition, 3)
		rootPart.Anchored = true
		rootPart.CFrame = CFrame.new(regionPosition + Vector3.new(0, 4, 0))
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		task.wait(0.5)
		rootPart.Anchored = false

		local deadline = os.clock() + 4
		repeat
			refreshQuestDefinitions()
			questGiver = findQuestGiver(questKey)

			if questGiver then
				break
			end

			task.wait(0.15)
		until os.clock() >= deadline

		if not questGiver then
			return false
		end
	end

	local _, _, rootPart = getCharacter()
	local npcRoot = questGiver:FindFirstChild("HumanoidRootPart") or questGiver.PrimaryPart
	if not rootPart or not npcRoot then
		return false
	end

	local destination = (npcRoot.CFrame * CFrame.new(0, 0, 3.5)).Position
	rootPart.CFrame = CFrame.lookAt(destination, npcRoot.Position)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	task.wait(0.15)

	return (rootPart.Position - npcRoot.Position).Magnitude <= 8
end
local function getInventoryFolder()
	local data = getPlayerData()
	local inventoryRoot = data and data:FindFirstChild("Inventory")
	return inventoryRoot and inventoryRoot:FindFirstChild("Inventory")
end

local function getInventoryItemAmount(itemName)
	if type(itemName) ~= "string" or itemName == "" then
		return 0
	end

	local inventory = getInventoryFolder()
	local item = inventory and inventory:FindFirstChild(itemName)
	if not item then
		return 0
	end

	local amount = item:FindFirstChild("Amount")
	return amount and amount.Value or 1
end

local function getTaskRemaining(task)
	local value = task and task:FindFirstChild("Value")
	local maximum = task and task:FindFirstChild("Max")

	if not maximum then
		return 1
	end

	return math.max(maximum.Value - (value and value.Value or 0), 0)
end
local function getTaskMaximum(task)
	local maximum = task and task:FindFirstChild("Max")
	return maximum and maximum.Value or 1
end

local function getTaskSpec(definition, taskName)
	local taskSpecs = definition and definition.TaskSpecs
	return type(taskSpecs) == "table" and taskSpecs[taskName] or nil
end

local function findStationaryNpcByName(name)
	if type(name) ~= "string" or name == "" then
		return nil
	end

	local _, _, rootPart = getCharacter()
	if not rootPart then
		return nil
	end

	local searchRoot = workspace:FindFirstChild("Debree")
	searchRoot = searchRoot and searchRoot:FindFirstChild("Regions") or workspace

	local nearestNpc
	local nearestDistance = math.huge

	for _, instance in ipairs(searchRoot:GetDescendants()) do
		if instance:IsA("Model") and instance.Name == name then
			local npcRoot = instance:FindFirstChild("HumanoidRootPart") or instance.PrimaryPart
			if npcRoot then
				local distance = (rootPart.Position - npcRoot.Position).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearestNpc = instance
				end
			end
		end
	end

	return nearestNpc
end

local function getQuestGrantedItems(definition)
	local grantedItems = {}

	if type(definition.GrantItemOnAccept) == "string" then
		grantedItems[definition.GrantItemOnAccept] = true
	end

	if type(definition.TaskSpecs) == "table" then
		for _, spec in pairs(definition.TaskSpecs) do
			if type(spec) == "table" and type(spec.GrantItem) == "string" then
				grantedItems[spec.GrantItem] = true
			end
		end
	end

	return grantedItems
end

local function isTaskAutomatable(questKey, definition, task, grantedItems)
	local spec = getTaskSpec(definition, task.Name)

	if spec then
		local taskType = spec.Type

		if taskType == "Pickup" then
			return spec.Positions ~= nil
		end

		if taskType == "Deliver" then
			if type(spec.TargetNpc) ~= "string" or spec.TargetNpc == "" then
				return false
			end

			if type(spec.RequiredItem) == "string" then
				local requiredAmount = spec.Count or getTaskRemaining(task)
				return grantedItems[spec.RequiredItem] == true or getInventoryItemAmount(spec.RequiredItem) >= requiredAmount
			end

			return true
		end

		if taskType == "DeliverAny" then
			if type(spec.TargetNpc) ~= "string" or spec.TargetNpc == "" then
				return false
			end

			if type(spec.RequiredItems) ~= "table" then
				return false
			end

			local totalAmount = 0
			for _, itemName in ipairs(spec.RequiredItems) do
				totalAmount += getInventoryItemAmount(itemName)
			end

			return totalAmount >= getTaskRemaining(task)
		end

		if taskType == "Deposit" then
			if type(spec.RequiredItem) ~= "string" or typeof(spec.Position) ~= "Vector3" then
				return false
			end

			return getInventoryItemAmount(spec.RequiredItem) >= getTaskRemaining(task)
		end

		if taskType == "Collect" then
			if type(spec.RequiredItem) ~= "string" then
				return false
			end

			return getInventoryItemAmount(spec.RequiredItem) >= getTaskRemaining(task)
		end

		if taskType ~= nil then
			return false
		end
	end

	local code = task:FindFirstChild("Code")
	local npcCode = code and code.Value or nil
	if type(npcCode) ~= "string" or npcCode == "" then
		return false
	end

	return true
end

isQuestFarmable = function(questKey)
	local definition = questDefinitions[questKey] or Quests.Holder[questKey]
	if not definition or typeof(definition.QuestInstance) ~= "Instance" then
		return false
	end

	if questKey == "Ill walk the order" then
		return true
	end

	if type(definition.OfferNpc) ~= "string" or definition.OfferNpc == "" then
		return false
	end

	local tasks = definition.QuestInstance:FindFirstChild("Tasks")
	if not tasks then
		return false
	end

	local grantedItems = getQuestGrantedItems(definition)
	local activeQuest = getActiveQuest(questKey)
	local activeTasks = activeQuest and activeQuest:FindFirstChild("Tasks") or nil
	local taskCount = 0

	for _, templateTask in ipairs(tasks:GetChildren()) do
		taskCount += 1
		local task = activeTasks and activeTasks:FindFirstChild(templateTask.Name) or templateTask
		if getTaskRemaining(task) > 0 and not isTaskAutomatable(questKey, definition, task, grantedItems) then
			return false
		end
	end

	return taskCount > 0
end

local function moveToWorldPosition(position)
	if typeof(position) == "CFrame" then
		position = position.Position
	end

	if typeof(position) ~= "Vector3" then
		return false
	end

	local _, _, rootPart = getCharacter()
	if not rootPart then
		return false
	end

	pcall(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, position, 2)
	rootPart.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	task.wait(0.18)

	return true
end

local function moveToNamedNpc(name)
	local npc = findStationaryNpcByName(name)

	if not npc then
		local position = staticNamedNpcPositions[name]
		local _, _, rootPart = getCharacter()

		if position and rootPart then
			pcall(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, position, 3)
			rootPart.CFrame = CFrame.new(position + Vector3.new(0, 4, 0))
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero

			local deadline = os.clock() + 4
			repeat
				npc = findStationaryNpcByName(name)
				if npc then
					break
				end
				task.wait(0.15)
			until os.clock() >= deadline
		end
	end

	if not npc then
		return false
	end

	local _, _, rootPart = getCharacter()
	local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
	if not rootPart or not npcRoot then
		return false
	end

	local destination = (npcRoot.CFrame * CFrame.new(0, 0, 3.5)).Position
	rootPart.CFrame = CFrame.lookAt(destination, npcRoot.Position)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	task.wait(0.12)

	return (rootPart.Position - npcRoot.Position).Magnitude <= 8
end

function Automation.getLiveCoinEntries()
	local entries = {}
	local seenSlots = {}

	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant:IsA("ProximityPrompt")
			and descendant.Enabled
			and descendant.ActionText == "Pick Up"
			and descendant.ObjectText == "Coin"
		then
			local pickup = descendant.Parent

			while pickup and pickup ~= workspace do
				local slotIndex = tonumber(pickup.Name:match("^Coin(%d+)$"))

				if slotIndex then
					if not seenSlots[slotIndex] then
						local position = getWorldPosition(pickup)

						if position then
							seenSlots[slotIndex] = true
							table.insert(entries, {
								Slot = slotIndex,
								Position = position,
								Prompt = descendant,
							})
						end
					end

					break
				end

				pickup = pickup.Parent
			end
		end
	end

	table.sort(entries, function(left, right)
		return left.Slot < right.Slot
	end)

	return entries
end
function Automation.moveSmoothlyToQuestPoint(position, generation)
	local _, _, rootPart = getCharacter()
	if not rootPart or typeof(position) ~= "Vector3" then
		return false
	end

	if activePositionTween then
		activePositionTween:Cancel()
		activePositionTween = nil
	end

	local hoverCFrame = CFrame.new(position + Vector3.new(0, 5.5, 0))
	local landingCFrame = CFrame.new(position + Vector3.new(0, 1.65, 0))
	local approachDistance = (rootPart.Position - hoverCFrame.Position).Magnitude
	local approachDuration = math.clamp(approachDistance / 650, 0.035, 0.14)

	rootPart.Anchored = true
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	local approachTween = TweenService:Create(
		rootPart,
		TweenInfo.new(approachDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{CFrame = hoverCFrame}
	)
	approachTween:Play()
	approachTween.Completed:Wait()

	if not farmEnabled or farmGeneration ~= generation or safeRetreatActive then
		rootPart.Anchored = false
		return false
	end

	local landingTween = TweenService:Create(
		rootPart,
		TweenInfo.new(0.085, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{CFrame = landingCFrame}
	)
	landingTween:Play()
	landingTween.Completed:Wait()

	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.Anchored = false

	return farmEnabled and farmGeneration == generation and not safeRetreatActive
end

function Automation.performFastCoinTask(questKey, questTask, generation)
	local value = questTask:FindFirstChild("Value")
	local maximum = questTask:FindFirstChild("Max")
	if not value or not maximum then
		return
	end

	moveToWorldPosition(Vector3.new(675, 1018.7, 134))

	while farmEnabled and farmGeneration == generation and questTask.Parent and value.Value < maximum.Value do
		if safeRetreatActive then
			return
		end

		local entries = Automation.getLiveCoinEntries()
		if #entries == 0 then
			task.wait(0.05)
			continue
		end

		local _, _, rootPart = getCharacter()
		if not rootPart then
			return
		end

		table.sort(entries, function(left, right)
			return (left.Position - rootPart.Position).Magnitude < (right.Position - rootPart.Position).Magnitude
		end)

		local entry = entries[1]
		local previousValue = value.Value

		if not Automation.moveSmoothlyToQuestPoint(entry.Position, generation) then
			return
		end

		if entry.Prompt and entry.Prompt.Parent and entry.Prompt.Enabled then
			triggerPrompt(entry.Prompt)
		end

		local promptDeadline = os.clock() + 0.14
		while os.clock() < promptDeadline and value.Value == previousValue do
			task.wait(0.01)
		end

		if value.Value == previousValue then
			SignalEvent:FireServer("QuestProgress", questKey, questTask.Name, entry.Slot)

			local serverDeadline = os.clock() + 0.28
			while os.clock() < serverDeadline and value.Value == previousValue do
				task.wait(0.01)
			end
		end

		if value.Value == previousValue then
			Automation.moveSmoothlyToQuestPoint(entry.Position + Vector3.new(0, -0.25, 0), generation)
			SignalEvent:FireServer("QuestProgress", questKey, questTask.Name, entry.Slot)
			task.wait(0.05)
		else
			task.wait(0.015)
		end
	end
end

local function performPickupTask(questKey, questTask, spec, generation)
	local positions = spec.Positions
	local slotCount = typeof(positions) == "function" and (spec.SpawnCount or 1) or #positions
	local value = questTask:FindFirstChild("Value")
	local maximum = questTask:FindFirstChild("Max")

	for slotIndex = 1, slotCount do
		if not farmEnabled or farmGeneration ~= generation or safeRetreatActive then
			return
		end

		if value and maximum and value.Value >= maximum.Value then
			return
		end

		local pickedAttribute = questTask:GetAttribute("Picked" .. slotIndex)
		if pickedAttribute == true then
			continue
		end

		local success, position = pcall(function()
			if typeof(positions) == "function" then
				return positions(slotIndex)
			end
			return positions[slotIndex]
		end)

		if not success or not position then
			continue
		end

		for _ = 1, 6 do
			if not farmEnabled or farmGeneration ~= generation or safeRetreatActive then
				return
			end

			local previousValue = value and value.Value or 0

			if Automation.moveSmoothlyToQuestPoint(position, generation) then
				task.wait(0.04)
				SignalEvent:FireServer("QuestProgress", questKey, questTask.Name, slotIndex)
			end

			local accepted = false
			local deadline = os.clock() + 0.9

			while os.clock() < deadline do
				if questTask:GetAttribute("Picked" .. slotIndex) == true then
					accepted = true
					break
				end

				if value and value.Value > previousValue then
					accepted = true
					break
				end

				if value and maximum and value.Value >= maximum.Value then
					return
				end

				task.wait(0.05)
			end

			if accepted then
				break
			end
		end
	end
end

local function performDeliverTask(questKey, questTask, spec)
	if not moveToNamedNpc(spec.TargetNpc) then
		return
	end

	if type(spec.RequiredItem) == "string" then
		local requiredAmount = spec.Count or getTaskMaximum(questTask)
		if getInventoryItemAmount(spec.RequiredItem) < requiredAmount then
			return
		end
	end

	SignalEvent:FireServer("QuestProgress", questKey, questTask.Name)
	task.wait(0.25)
end

local function performDeliverAnyTask(questKey, questTask, spec, generation)
	if not moveToNamedNpc(spec.TargetNpc) then
		return
	end

	for _ = 1, getTaskMaximum(questTask) do
		if not farmEnabled or farmGeneration ~= generation or safeRetreatActive then
			return
		end

		local totalAmount = 0
		for _, itemName in ipairs(spec.RequiredItems or {}) do
			totalAmount += getInventoryItemAmount(itemName)
		end

		if totalAmount <= 0 then
			return
		end

		SignalEvent:FireServer("QuestProgress", questKey, questTask.Name)
		task.wait(0.2)

		local value = questTask:FindFirstChild("Value")
		local maximum = questTask:FindFirstChild("Max")
		if value and maximum and value.Value >= maximum.Value then
			return
		end
	end
end

local function performDepositTask(questKey, questTask, spec, generation)
	if not moveToWorldPosition(spec.Position) then
		return
	end

	for _ = 1, getTaskMaximum(questTask) do
		if not farmEnabled or farmGeneration ~= generation or safeRetreatActive then
			return
		end

		if getInventoryItemAmount(spec.RequiredItem) <= 0 then
			return
		end

		SignalEvent:FireServer("QuestProgress", questKey, questTask.Name)
		task.wait(0.18)

		local value = questTask:FindFirstChild("Value")
		local maximum = questTask:FindFirstChild("Max")
		if value and maximum and value.Value >= maximum.Value then
			return
		end
	end
end

local function performCollectTask(questKey, questTask, spec)
	if getInventoryItemAmount(spec.RequiredItem) <= 0 then
		return
	end

	SignalEvent:FireServer("QuestProgress", questKey, questTask.Name)
	task.wait(0.25)
end

local function takeQuest(questKey)
	if not moveToQuestGiver(questKey) then
		return false
	end

	refreshQuestDefinitions()

	if not canTakeQuest(questKey) then
		return false
	end

	SignalEvent:FireServer("AddQuest", questKey)
	return true
end
local function getRetreatThreatRoot()
	local target = currentCombatTarget
	if target and target.Parent then
		local humanoid = target:FindFirstChildOfClass("Humanoid")
		local targetRoot = target:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and targetRoot then
			return targetRoot
		end
	end
	return nil
end

local function beginSafeRetreat()
	local _, _, rootPart = getCharacter()
	if not rootPart then
		return false
	end

	if not safeReturnCFrame then
		safeReturnCFrame = rootPart.CFrame
	end

	local threatRoot = getRetreatThreatRoot()
	local direction

	if threatRoot then
		direction = Vector3.new(
			safeReturnCFrame.Position.X - threatRoot.Position.X,
			0,
			safeReturnCFrame.Position.Z - threatRoot.Position.Z
		)

		if direction.Magnitude < 0.1 then
			local lookVector = threatRoot.CFrame.LookVector
			direction = Vector3.new(-lookVector.X, 0, -lookVector.Z)
		end
	else
		local lookVector = rootPart.CFrame.LookVector
		direction = Vector3.new(-lookVector.X, 0, -lookVector.Z)
	end

	if direction.Magnitude < 0.1 then
		direction = Vector3.new(1, 0, 0)
	end

	safeRetreatDirection = direction.Unit

	return true
end

local function getSafeRetreatPosition()
	local _, _, rootPart = getCharacter()
	if not rootPart then
		return nil
	end

	if not safeReturnCFrame or not safeRetreatDirection then
		if not beginSafeRetreat() then
			return nil
		end
	end

	local threatRoot = getRetreatThreatRoot()
	local originPosition = threatRoot and threatRoot.Position or safeReturnCFrame.Position
	local desiredPosition = originPosition + safeRetreatDirection * safeDistance
	local raycastParams = RaycastParams.new()
	local map = workspace:FindFirstChild("Map")

	if map then
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = {map}
	end

	local rayOrigin = Vector3.new(desiredPosition.X, math.max(rootPart.Position.Y + 200, desiredPosition.Y + 200), desiredPosition.Z)
	local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -700, 0), raycastParams)

	if rayResult then
		return rayResult.Position + Vector3.new(0, 3, 0)
	end

	return Vector3.new(desiredPosition.X, safeReturnCFrame.Position.Y, desiredPosition.Z)
end

local function maintainSafeDistance()
	local retreatPosition = getSafeRetreatPosition()
	local _, _, rootPart = getCharacter()

	if not retreatPosition or not rootPart then
		return false
	end

	rootPart.Anchored = false
	rootPart.CFrame = CFrame.new(retreatPosition)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	return true
end

local function returnFromSafeRetreat()
	local _, _, rootPart = getCharacter()

	if rootPart and safeReturnCFrame then
		rootPart.Anchored = false
		rootPart.CFrame = safeReturnCFrame
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end

	safeReturnCFrame = nil
	safeRetreatDirection = nil
	safeRetreatActive = false
end

local function runAutoSafeLoop(generation)
	while autoSafeEnabled and autoSafeGeneration == generation do
		local currentHealth, maximumHealth = getDisplayedHealth()

		if currentHealth and maximumHealth and currentHealth <= safeHealthThreshold then
			if not safeRetreatActive then
				safeRetreatActive = beginSafeRetreat()
			end

			setBlocking(false)

			while autoSafeEnabled and autoSafeGeneration == generation and safeRetreatActive do
				local healthNow = getDisplayedHealth()
				if not healthNow then
					break
				end

				if healthNow > safeHealthThreshold then
					break
				end

				maintainSafeDistance()
				task.wait(0.15)
			end

			returnFromSafeRetreat()
		end

		task.wait(0.1)
	end

	if safeReturnCFrame then
		returnFromSafeRetreat()
	else
		safeRetreatActive = false
	end
end
local function performCombatQuestTask(questKey, activeQuest, questTask, generation)
	local code = questTask:FindFirstChild("Code")
	local npcCode = code and code.Value or nil

	if type(npcCode) ~= "string" or npcCode == "" then
		setBlocking(false)
		task.wait(0.5)
		return
	end

	local questPosition = getQuestPosition(questKey, questTask)

	if not questPosition and npcCode == "VillageSpy" then
		questPosition = Vector3.new(-687, 1260.5, -1103)
	end

	if not questPosition then
		local catalogEntry = staticQuestCatalog[questKey]
		questPosition = catalogEntry and (catalogEntry.Position or staticRegionPositions[catalogEntry.Region]) or nil
	end

	local target = getNearestNpc(npcCode, questPosition)

	if not target then
		setBlocking(false)
		if questPosition then
			moveToQuestArea(questPosition)
		end
		task.wait(0.75)
		return
	end

	fightTarget(target, activeQuest, questTask, generation)
	task.wait(0.15)
end

Automation.lanternPlateSequences = setmetatable({}, {__mode = "k"})

function Automation.getLanternPlateEntries()
	local map = workspace:FindFirstChild("Map")
	local puzzles = map and map:FindFirstChild("Puzzles")
	local root = puzzles and puzzles:FindFirstChild("FLLanternPlates")
	if not root then
		return {}
	end

	local entries = {}
	local taggedPlates = CollectionService:GetTagged("SimonPlate")
	local candidates = #taggedPlates > 0 and taggedPlates or root:GetChildren()

	for _, model in ipairs(candidates) do
		if model ~= root
			and root:IsAncestorOf(model)
			and type(model:GetAttribute("SimonIndex")) == "number"
		then
			local bestPart
			local bestScore = -math.huge
			local touchParts = {}

			for _, descendant in ipairs(model:GetDescendants()) do
				if descendant:IsA("BasePart") then
					local name = descendant.Name:lower()
					local score = descendant.Size.X * descendant.Size.Z
					local hasTouchTransmitter = descendant:FindFirstChildOfClass("TouchTransmitter") ~= nil

					if descendant.CanTouch then
						touchParts[#touchParts + 1] = descendant
						score += 5000
					end

					if hasTouchTransmitter then
						score += 100000
					end

					if descendant.Parent == model and descendant.Name ~= "Base" then
						score += 30000
					end

					if name:find("plate", 1, true)
						or name:find("touch", 1, true)
						or name:find("pad", 1, true)
						or name:find("hitbox", 1, true)
					then
						score += 20000
					end

					if score > bestScore then
						bestScore = score
						bestPart = descendant
					end
				end
			end

			if bestPart then
				if #touchParts == 0 then
					touchParts[1] = bestPart
				end

				entries[#entries + 1] = {
					Model = model,
					Part = bestPart,
					TouchParts = touchParts,
					Index = model:GetAttribute("SimonIndex"),
				}
			end
		end
	end

	table.sort(entries, function(left, right)
		return left.Index < right.Index
	end)

	return entries
end

function Automation.getLanternVisualState(entry)
	local state = {}

	if not entry or not entry.Model or not entry.Model.Parent then
		return state
	end

	for _, descendant in ipairs(entry.Model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			state[descendant] = {
				Kind = "Part",
				Color = descendant.Color,
				Material = descendant.Material,
				Transparency = descendant.Transparency,
				Reflectance = descendant.Reflectance,
			}
		elseif descendant:IsA("Light") then
			state[descendant] = {
				Kind = "Light",
				Enabled = descendant.Enabled,
				Brightness = descendant.Brightness,
				Color = descendant.Color,
			}
		elseif descendant:IsA("ParticleEmitter")
			or descendant:IsA("Beam")
			or descendant:IsA("Trail")
			or descendant:IsA("Highlight")
		then
			state[descendant] = {
				Kind = "Effect",
				Enabled = descendant.Enabled,
			}
		end
	end

	return state
end

function Automation.lanternYellowColorScore(color)
	local hue, saturation, value = color:ToHSV()
	local centerHue = 0.145
	local hueDistance = math.abs(hue - centerHue)
	hueDistance = math.min(hueDistance, 1 - hueDistance)

	if hueDistance > 0.12 or saturation < 0.22 or value < 0.35 then
		return 0
	end

	return (1 - hueDistance / 0.12) * saturation * value
end

function Automation.getLanternYellowGlow(entry)
	if not entry or not entry.Model or not entry.Model.Parent then
		return 0
	end

	local strongest = 0

	for _, descendant in ipairs(entry.Model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Transparency < 0.98 then
			local score = Automation.lanternYellowColorScore(descendant.Color)

			if descendant.Material == Enum.Material.Neon then
				score *= 1.6
			end

			strongest = math.max(strongest, score)
		elseif descendant:IsA("Light") and descendant.Enabled then
			local score = Automation.lanternYellowColorScore(descendant.Color)
			score *= 1 + math.min(descendant.Brightness, 5) * 0.12
			strongest = math.max(strongest, score)
		elseif descendant:IsA("Highlight") and descendant.Enabled then
			strongest = math.max(
				strongest,
				Automation.lanternYellowColorScore(descendant.FillColor) * (1 - descendant.FillTransparency),
				Automation.lanternYellowColorScore(descendant.OutlineColor) * (1 - descendant.OutlineTransparency)
			)
		elseif (descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") or descendant:IsA("Trail"))
			and descendant.Enabled
		then
			for _, keypoint in ipairs(descendant.Color.Keypoints) do
				strongest = math.max(strongest, Automation.lanternYellowColorScore(keypoint.Value))
			end
		end
	end

	return strongest
end

function Automation.getLanternStateDelta(currentState, baselineState)
	local score = 0

	for instance, baseline in pairs(baselineState) do
		local current = currentState[instance]

		if current and current.Kind == baseline.Kind then
			if current.Kind == "Part" then
				local colorDelta = math.abs(current.Color.R - baseline.Color.R)
					+ math.abs(current.Color.G - baseline.Color.G)
					+ math.abs(current.Color.B - baseline.Color.B)

				score += colorDelta * 5
				score += math.abs(current.Transparency - baseline.Transparency) * 2
				score += math.abs(current.Reflectance - baseline.Reflectance)

				if current.Material ~= baseline.Material then
					score += 3
				end
			elseif current.Kind == "Light" then
				local colorDelta = math.abs(current.Color.R - baseline.Color.R)
					+ math.abs(current.Color.G - baseline.Color.G)
					+ math.abs(current.Color.B - baseline.Color.B)

				score += colorDelta * 4
				score += math.abs(current.Brightness - baseline.Brightness) * 0.75

				if current.Enabled ~= baseline.Enabled then
					score += 5
				end
			elseif current.Kind == "Effect" and current.Enabled ~= baseline.Enabled then
				score += 4
			end
		end
	end

	return score
end

function Automation.getLanternHighlightScore(entry, baselineState)
	return Automation.getLanternStateDelta(
		Automation.getLanternVisualState(entry),
		baselineState
	)
end

function Automation.waitLanternQuiet(entries, timeout)
	local states = {}

	for index, entry in ipairs(entries) do
		states[index] = Automation.getLanternVisualState(entry)
	end

	local stableSince = os.clock()
	local deadline = os.clock() + timeout

	while os.clock() < deadline do
		local currentStates = {}
		local maximumDelta = 0

		for index, entry in ipairs(entries) do
			local currentState = Automation.getLanternVisualState(entry)
			currentStates[index] = currentState
			maximumDelta = math.max(
				maximumDelta,
				Automation.getLanternStateDelta(currentState, states[index] or {})
			)
		end

		if maximumDelta > 0.04 then
			stableSince = os.clock()
			states = currentStates
		elseif os.clock() - stableSince >= 0.35 then
			return currentStates
		end

		task.wait(0.02)
	end

	return states
end
function Automation.waitLanternDisplayFinished(entries, baseline, generation, timeout)
	local deadline = os.clock() + timeout
	local quietSince
	local releaseThreshold = 0.06

	while farmEnabled
		and farmGeneration == generation
		and not safeRetreatActive
		and os.clock() < deadline
	do
		local maximumScore = 0

		for index, entry in ipairs(entries) do
			maximumScore = math.max(
				maximumScore,
				Automation.getLanternHighlightScore(entry, baseline[index] or {})
			)
		end

		if maximumScore <= releaseThreshold then
			quietSince = quietSince or os.clock()

			if os.clock() - quietSince >= 0.55 then
				return true
			end
		else
			quietSince = nil
		end

		task.wait(0.015)
	end

	return false
end

function Automation.captureLanternSequence(entries, baseline, expectedLength, startTimeout, generation, darkGlowSeed)
	local sequence = {}
	local activeIndex
	local firstHighlightDeadline = os.clock() + startTimeout
	local lastHighlightAt
	local darkGlow = {}
	local currentGlow = {}
	local triggerRise = 0.09
	local releaseRise = 0.035

	for index, entry in ipairs(entries) do
		local glow = Automation.getLanternYellowGlow(entry)
		local seededGlow = darkGlowSeed and darkGlowSeed[index]

		if type(seededGlow) == "number" then
			darkGlow[index] = math.min(seededGlow, glow)
		else
			darkGlow[index] = glow
		end

		currentGlow[index] = glow
	end

	while farmEnabled
		and farmGeneration == generation
		and not safeRetreatActive
		and #sequence < expectedLength
	do
		local maximumRise = 0
		local maximumIndex

		for index, entry in ipairs(entries) do
			local glow = Automation.getLanternYellowGlow(entry)
			currentGlow[index] = glow
			darkGlow[index] = math.min(darkGlow[index] or glow, glow)

			local rise = glow - (darkGlow[index] or 0)
			if rise > maximumRise then
				maximumRise = rise
				maximumIndex = index
			end
		end

		if activeIndex then
			local activeRise = (currentGlow[activeIndex] or 0) - (darkGlow[activeIndex] or 0)
			if activeRise <= releaseRise then
				activeIndex = nil
			end
		elseif maximumIndex and maximumRise >= triggerRise then
			activeIndex = maximumIndex
			sequence[#sequence + 1] = entries[maximumIndex]
			lastHighlightAt = os.clock()
		end

		local now = os.clock()

		if #sequence == 0 then
			if now >= firstHighlightDeadline then
				break
			end
		elseif lastHighlightAt and now - lastHighlightAt >= 2.5 then
			break
		end

		task.wait(0.01)
	end

	if #sequence == expectedLength then
		local quietSince
		local quietDeadline = os.clock() + 4

		while farmEnabled
			and farmGeneration == generation
			and not safeRetreatActive
			and os.clock() < quietDeadline
		do
			local anyActive = false

			for index, entry in ipairs(entries) do
				local glow = Automation.getLanternYellowGlow(entry)
				darkGlow[index] = math.min(darkGlow[index] or glow, glow)

				if glow - (darkGlow[index] or 0) > releaseRise then
					anyActive = true
					break
				end
			end

			if anyActive then
				quietSince = nil
			else
				quietSince = quietSince or os.clock()
				if os.clock() - quietSince >= 0.3 then
					break
				end
			end

			task.wait(0.01)
		end
	end

	return sequence, darkGlow
end

function Automation.touchLanternPlate(entry)
	if not entry or not entry.Part or not entry.Part.Parent then
		return false
	end

	local character, humanoid, rootPart = getCharacter()
	if not character or not humanoid or not rootPart then
		return false
	end

	local part = entry.Part
	local standingHeight = part.Size.Y * 0.5 + humanoid.HipHeight + rootPart.Size.Y * 0.5
	local hoverCFrame = part.CFrame * CFrame.new(0, standingHeight + 5, 0)
	local preLandingCFrame = part.CFrame * CFrame.new(0, standingHeight + 1.15, 0)
	local distance = (rootPart.Position - hoverCFrame.Position).Magnitude
	local approachDuration = math.clamp(distance / 520, 0.04, 0.18)

	rootPart.Anchored = true
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	local approachTween = TweenService:Create(
		rootPart,
		TweenInfo.new(approachDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{CFrame = hoverCFrame}
	)
	approachTween:Play()
	approachTween.Completed:Wait()

	rootPart.CFrame = preLandingCFrame
	rootPart.Anchored = false
	rootPart.AssemblyLinearVelocity = -part.CFrame.UpVector * 18
	rootPart.AssemblyAngularVelocity = Vector3.zero
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

	local fireTouch = rawget(getfenv(), "firetouchinterest")
	if type(fireTouch) == "function" and rootPart.CanTouch and part.CanTouch then
		-- Exactly one synthetic contact. Firing every body part against every
		-- plate part can submit the same Simon input multiple times.
		pcall(fireTouch, rootPart, part, 0)
		pcall(fireTouch, rootPart, part, 1)
	end

	task.wait(0.24)

	if not rootPart.Parent then
		return false
	end

	rootPart.Anchored = true
	rootPart.CFrame = hoverCFrame
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	return true
end

function Automation.waitLanternRound(value, targetRound, timeout)
	local deadline = os.clock() + timeout

	while os.clock() < deadline do
		if value.Value >= targetRound then
			return true
		end
		task.wait(0.04)
	end

	return value.Value >= targetRound
end

function Automation.forceLanternDisplay(entries, value, baseline)
	local roundBefore = value.Value

	for index = 1, math.min(#entries, 6) do
		if not farmEnabled or safeRetreatActive then
			return {}
		end

		Automation.touchLanternPlate(entries[index])

		if value.Value ~= roundBefore then
			break
		end
	end

	local expectedLength = math.clamp(value.Value + 1, 1, 5)
	return Automation.captureLanternSequence(entries, baseline, expectedLength, 4, farmGeneration)
end

function Automation.performLanternPlateTrial(questTask, generation)
	local value = questTask:FindFirstChild("Value")
	local maximum = questTask:FindFirstChild("Max")
	if not value or not maximum then
		return
	end

	Automation.suspendNoclip = true
	updateNoclip()
	RunService.Heartbeat:Wait()

	pcall(function()
		local trialPosition = Vector3.new(1079, 1422, -781)
		pcall(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, trialPosition, 4)
		moveToWorldPosition(trialPosition)

		local entries = {}
		local loadDeadline = os.clock() + 8

		repeat
			entries = Automation.getLanternPlateEntries()
			if #entries >= 9 then
				break
			end
			task.wait(0.1)
		until os.clock() >= loadDeadline

		if #entries == 0 then
			return
		end

		local byIndex = {}
		local center = Vector3.zero
		local highestY = -math.huge

		for _, entry in ipairs(entries) do
			byIndex[entry.Index] = entry
			center += entry.Part.Position
			highestY = math.max(highestY, entry.Part.Position.Y)
		end

		center /= #entries
		local observationPosition = Vector3.new(center.X, highestY + 18, center.Z)
		local consumedShowSerial = 0

		while farmEnabled and farmGeneration == generation and questTask.Parent and value.Value < maximum.Value do
			if safeRetreatActive then
				return
			end

			local _, _, rootPart = getCharacter()
			if not rootPart then
				return
			end

			rootPart.Anchored = true
			rootPart.CFrame = CFrame.new(observationPosition)
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero

			local show
			local showDeadline = os.clock() + 12

			repeat
				local candidate = Automation.lanternLastShow
				if candidate and candidate.Serial > consumedShowSerial then
					show = candidate
					break
				end
				task.wait(0.02)
			until os.clock() >= showDeadline
				or not farmEnabled
				or farmGeneration ~= generation
				or safeRetreatActive

			if not show then
				continue
			end

			consumedShowSerial = show.Serial

			local sequence = {}
			local validSequence = true

			for _, plateIndex in ipairs(show.Plates) do
				local entry = byIndex[plateIndex]
				if not entry then
					validSequence = false
					break
				end
				sequence[#sequence + 1] = entry
			end

			if not validSequence or #sequence == 0 then
				continue
			end

			-- The client controller shows each plate for Step*0.6 and leaves
			-- Step*0.4 between flashes. Wait until the exact server sequence ends.
			local displayEndsAt = show.ReceivedAt + show.Lead + show.Step * #show.Plates + 0.12
			while os.clock() < displayEndsAt do
				if not farmEnabled or farmGeneration ~= generation or safeRetreatActive then
					return
				end
				task.wait(0.01)
			end

			local roundBefore = value.Value
			local failed = false

			for _, entry in ipairs(sequence) do
				if not farmEnabled or farmGeneration ~= generation or safeRetreatActive then
					return
				end

				local responseBefore = Automation.lanternResponseSerial

				if not Automation.touchLanternPlate(entry) then
					return
				end

				local response
				local responseDeadline = os.clock() + 1.25

				repeat
					local candidate = Automation.lanternLastResponse
					if candidate and candidate.Serial > responseBefore then
						response = candidate
						break
					end

					if value.Value > roundBefore then
						break
					end

					task.wait(0.015)
				until os.clock() >= responseDeadline

				if response then
					if response.Action == "Fail" then
						failed = true
						break
					end

					if response.Action == "Step"
						and type(response.Plate) == "number"
						and response.Plate ~= entry.Index
					then
						failed = true
						break
					end
				elseif value.Value <= roundBefore then
					-- Do not submit the next plate unless the server confirmed
					-- this one. Waiting is safer than creating a wrong input.
					failed = true
					break
				end

				task.wait(0.05)
			end

			if failed then
				Automation.lanternPlateSequences[questTask] = nil
				task.wait(0.1)
				continue
			end

			if Automation.waitLanternRound(value, roundBefore + 1, 2.5) then
				Automation.lanternPlateSequences[questTask] = table.clone(sequence)
			else
				Automation.lanternPlateSequences[questTask] = nil
				task.wait(0.1)
			end
		end
	end)

	local _, _, rootPart = getCharacter()
	if rootPart then
		rootPart.Anchored = false
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end

	Automation.suspendNoclip = false
	updateNoclip()
end
local function performQuestTask(questKey, activeQuest, questTask, generation)
	if questKey == "Ill walk the order" then
		Automation.performLanternPlateTrial(questTask, generation)
		return
	end

	if questKey == "Ill look for the penny(Lv 14)" then
		performPickupTask(questKey, questTask, {
			Type = "Pickup",
			Positions = {Vector3.new(554.5, 1010.5499877929688, -214.5)},
		}, generation)
		return
	end

	if questKey == "Ill find the coins(Lv 21)" then
		Automation.performFastCoinTask(questKey, questTask, generation)
		return
	end

	if questKey == "Ill deliver the package" then
		performDeliverTask(questKey, questTask, {
			Type = "Deliver",
			TargetNpc = "Elara",
			RequiredItem = "Package",
			Count = 1,
		})
		return
	end

	if questKey == "Ill get this letter delivered" then
		performDeliverTask(questKey, questTask, {
			Type = "Deliver",
			TargetNpc = "Chaka",
			RequiredItem = "Letter",
			Count = 1,
		})
		return
	end

	local definition = questDefinitions[questKey] or Quests.Holder[questKey]
	local spec = definition and getTaskSpec(definition, questTask.Name)

	if not spec then
		performCombatQuestTask(questKey, activeQuest, questTask, generation)
		return
	end

	local taskType = spec.Type

	if taskType == "Pickup" then
		performPickupTask(questKey, questTask, spec, generation)
		return
	end

	if taskType == "Deliver" then
		performDeliverTask(questKey, questTask, spec)
		return
	end

	if taskType == "DeliverAny" then
		performDeliverAnyTask(questKey, questTask, spec, generation)
		return
	end

	if taskType == "Deposit" then
		performDepositTask(questKey, questTask, spec, generation)
		return
	end

	if taskType == "Collect" then
		performCollectTask(questKey, questTask, spec)
	end
end

local function runFarmLoop(generation)
	while farmEnabled and farmGeneration == generation do
		local questKey = selectedQuestKey

		if safeRetreatActive then
			task.wait(0.2)
			continue
		end

		if not questKey then
			setBlocking(false)
			task.wait(0.25)
			continue
		end

		local activeQuest = getActiveQuest(questKey)

		if not activeQuest then
			setBlocking(false)

			if getQuestState(questKey) ~= "Doing" then
				if takeQuest(questKey) then
					task.wait(0.8)
				else
					task.wait(0.5)
				end
			else
				task.wait(0.25)
			end

			continue
		end

		local questTask = getPendingQuestTask(activeQuest)
		if not questTask then
			setBlocking(false)
			task.wait(0.25)
			continue
		end

		performQuestTask(questKey, activeQuest, questTask, generation)
		task.wait(0.1)
	end

	setBlocking(false)
end

refreshQuestDefinitions()

local function getMobFarmOptions()
	local unique = {}

	for name in pairs(staticMobCatalog) do
		unique[name] = true
	end

	local regions = workspace:FindFirstChild("Humanoids")
	regions = regions and regions:FindFirstChild("Regions")

	if regions then
		for _, instance in ipairs(regions:GetDescendants()) do
			if instance:IsA("Model") then
				local humanoid = instance:FindFirstChildOfClass("Humanoid")
				local rootPart = instance:FindFirstChild("HumanoidRootPart")

				if humanoid and rootPart then
					local ancestor = instance.Parent
					local insideActiveNpcs = false

					while ancestor and ancestor ~= regions do
						if ancestor.Name == "ActiveNpcs" then
							insideActiveNpcs = true
							break
						end
						ancestor = ancestor.Parent
					end

					if insideActiveNpcs then
						local name = instance.Parent and instance.Parent:IsA("Folder") and instance.Parent.Name or instance.Name
						if not name:lower():find("civilian", 1, true) then
							unique[name] = true
						end
					end
				end
			end
		end
	end

	local options = {}
	for name in pairs(unique) do
		table.insert(options, name)
	end
	table.sort(options)

	return options
end

local function fightStandaloneTarget(target, generation, mode)
	currentCombatTarget = target
	if selectedWeaponName then
		Automation.equipSelectedWeapon()
	end
	local lastTargetPosition

	while isCombatAutomationActive(generation, mode) and not safeRetreatActive and target.Parent do
		local humanoid = target:FindFirstChildOfClass("Humanoid")
		local targetRoot = target:FindFirstChild("HumanoidRootPart")
		local character, _, rootPart = getCharacter()

		if targetRoot then
			lastTargetPosition = targetRoot.Position
		end

		if not humanoid or humanoid.Health <= 0 or not targetRoot then
			break
		end

		if not character or not rootPart then
			setBlocking(false)
			task.wait(0.25)
			continue
		end

		if handleIncomingAttack(target) then
			continue
		end

		moveNearTarget(target)

		if Automation.isTargetDefending(target) then
			setBlocking(false)
			task.wait(0.06)
			continue
		end

		setBlocking(false)

		local instantAttack = Automation.autoAttackMode == "Instant"

		if instantAttack or os.clock() >= nextCombatAttack then
			if not instantAttack then
				task.wait(0.04)
			end

			if Automation.isTargetDefending(target) then
				nextCombatAttack = os.clock() + 0.05
				continue
			end

			if not isCombatAutomationActive(generation, mode) then
				break
			end

			moveNearTarget(target)
			local serverHitDelay = performCombatAttack(generation, mode)
			if serverHitDelay and not instantAttack then
				Automation.waitCombatRecovery(target, serverHitDelay + 0.03, generation, mode)
			end
		end

		task.wait(instantAttack and 0.01 or 0.04)
	end

	if currentCombatTarget == target then
		currentCombatTarget = nil
	end

	setBlocking(false)

	local finalHumanoid = target:FindFirstChildOfClass("Humanoid")
	if lastTargetPosition and (not target.Parent or not finalHumanoid or finalHumanoid.Health <= 0) then
		claimNearbySouls(lastTargetPosition)
	end

	return lastTargetPosition
end

local function runMobFarmLoop(generation)
	while mobFarmEnabled and mobFarmGeneration == generation do
		if safeRetreatActive then
			task.wait(0.2)
			continue
		end

		if not selectedMobName then
			task.wait(0.25)
			continue
		end

		local target = getNearestNpc(selectedMobName)

		if not target then
			local catalogEntry = staticMobCatalog[selectedMobName]
			local streamPosition = catalogEntry and (catalogEntry.Position or staticRegionPositions[catalogEntry.Region])
			local _, _, rootPart = getCharacter()

			if streamPosition and rootPart then
				pcall(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, streamPosition, 3)
				rootPart.Anchored = true
				rootPart.CFrame = CFrame.new(streamPosition + Vector3.new(0, 4, 0))
				rootPart.AssemblyLinearVelocity = Vector3.zero
				rootPart.AssemblyAngularVelocity = Vector3.zero
				task.wait(0.8)
				rootPart.Anchored = false
			else
				task.wait(0.5)
			end

			continue
		end

		fightStandaloneTarget(target, generation, "Mob")
		task.wait(0.1)
	end

	if currentCombatTarget and not farmEnabled then
		currentCombatTarget = nil
	end

	setBlocking(false)
end
function Automation.isDungeonPlace()
	return workspace:GetAttribute("MinigameKey") == "Ouwigahara"
end

function Automation.getNearestDungeonEnemy()
	if not Automation.isDungeonPlace() then
		return nil
	end

	local _, _, rootPart = getCharacter()
	if not rootPart then
		return nil
	end

	local humanoidsRoot = workspace:FindFirstChild("Humanoids")
	if not humanoidsRoot then
		return nil
	end

	local nearest
	local nearestDistance = math.huge

	for _, model in ipairs(humanoidsRoot:GetDescendants()) do
		if model:IsA("Model") and Players:GetPlayerFromCharacter(model) == nil then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local targetRoot = model:FindFirstChild("HumanoidRootPart")

			if humanoid and targetRoot and humanoid.Health > 0 then
				local distance = (rootPart.Position - targetRoot.Position).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearest = model
				end
			end
		end
	end

	return nearest
end

function Automation.runAutoDungeonLoop(generation)
	while Automation.autoDungeonEnabled
		and Automation.autoDungeonGeneration == generation
		and Automation.isDungeonPlace()
	do
		if safeRetreatActive then
			task.wait(0.15)
			continue
		end

		local target = Automation.getNearestDungeonEnemy()
		if target then
			fightStandaloneTarget(target, generation, "Dungeon")
		else
			task.wait(0.2)
		end
	end

	setBlocking(false)
end

local function getChestCandidates()
	local candidates = {}
	local seen = {}

	for _, chest in ipairs(CollectionService:GetTagged("Chest")) do
		if chest:IsA("Model") and not seen[chest] then
			seen[chest] = true
			table.insert(candidates, chest)
		end
	end

	local chestsFolder = workspace:FindFirstChild("Chests")
	if chestsFolder then
		for _, chest in ipairs(chestsFolder:GetDescendants()) do
			if chest:IsA("Model") and not seen[chest] then
				local chestId = chest:GetAttribute("ChestId")
				local chestState = chest:GetAttribute("ChestState")
				if chestId ~= nil or chestState ~= nil then
					seen[chest] = true
					table.insert(candidates, chest)
				end
			end
		end
	end

	return candidates
end

local function getChestIdentity(chest)
	local chestId = chest:GetAttribute("ChestId")
	if type(chestId) == "string" and chestId ~= "" then
		return chestId
	end

	local chestModel = chest:GetAttribute("ChestModel")
	if type(chestModel) == "string" and chestModel ~= "" then
		return chestModel
	end

	return chest.Name
end

local function getNearestChest(originPosition, radius, sealedOnly)
	local nearestChest
	local nearestDistance = math.huge

	for _, chest in ipairs(getChestCandidates()) do
		if chest.Parent and chest:GetAttribute("IsOpen") ~= true then
			local identity = getChestIdentity(chest)
			local isSealed = identity:lower():find("sealed", 1, true) ~= nil or chest:GetAttribute("ChestState") ~= nil

			if not sealedOnly or isSealed then
				local position = getWorldPosition(chest)
				if position then
					local distance = originPosition and (position - originPosition).Magnitude or 0
					if (not radius or distance <= radius) and distance < nearestDistance then
						nearestDistance = distance
						nearestChest = chest
					end
				end
			end
		end
	end

	return nearestChest
end

local function activateChest(chest)
	if not chest or not chest.Parent or chest:GetAttribute("IsOpen") == true then
		return false
	end

	local position = getWorldPosition(chest)
	local _, _, rootPart = getCharacter()

	if position and rootPart then
		rootPart.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end

	for _, descendant in ipairs(chest:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and descendant.Enabled then
			if triggerPrompt(descendant) then
				return true
			end
		end
	end

	local globalFireClick = rawget(getfenv(), "fireclickdetector")
	if type(globalFireClick) == "function" then
		for _, descendant in ipairs(chest:GetDescendants()) do
			if descendant:IsA("ClickDetector") then
				local success = pcall(globalFireClick, descendant)
				if success then
					return true
				end
			end
		end
	end

	local globalFireTouch = rawget(getfenv(), "firetouchinterest")
	if type(globalFireTouch) == "function" and rootPart then
		local chestPart = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart", true)
		if chestPart then
			pcall(globalFireTouch, rootPart, chestPart, 0)
			pcall(globalFireTouch, rootPart, chestPart, 1)
			return true
		end
	end

	return false
end

function Automation.isLootDropEligible(drop)
	if not drop or not drop.Parent or not drop:IsA("BasePart") then
		return false
	end

	local claimedBy = drop:GetAttribute("DropClaimedBy")
	if claimedBy ~= nil then
		return false
	end

	local ownerUserId = drop:GetAttribute("DropOwnerUserId")
	if typeof(ownerUserId) == "number" and ownerUserId ~= LocalPlayer.UserId then
		return false
	end

	local reservedFor = drop:GetAttribute("DropReservedFor")
	if typeof(reservedFor) == "string"
		and not reservedFor:find("," .. LocalPlayer.UserId .. ",", 1, true)
	then
		return false
	end

	return true
end

function Automation.getNearestEligibleLootDrop(originPosition, radius)
	local nearestDrop
	local nearestDistance = math.huge

	for _, drop in ipairs(CollectionService:GetTagged("LootDrop")) do
		if Automation.isLootDropEligible(drop) then
			local target = drop:GetAttribute("DropTarget")
			local position = typeof(target) == "Vector3" and target or drop.Position
			local distance = (originPosition - position).Magnitude

			if (not radius or distance <= radius) and distance < nearestDistance then
				nearestDistance = distance
				nearestDrop = drop
			end
		end
	end

	return nearestDrop
end

function Automation.getNearestUnlockedDroppedChest(originPosition, radius)
	local nearestChest
	local nearestDistance = math.huge

	for _, chest in ipairs(getChestCandidates()) do
		if chest.Parent
			and chest:GetAttribute("IsOpen") ~= true
			and chest:GetAttribute("ChestState") ~= "Locked"
		then
			local position = getWorldPosition(chest)
			if position then
				local distance = (originPosition - position).Magnitude
				if distance <= radius and distance < nearestDistance then
					nearestDistance = distance
					nearestChest = chest
				end
			end
		end
	end

	return nearestChest
end

function Automation.collectEligibleLootDrop(drop)
	if not Automation.isLootDropEligible(drop) then
		return false
	end

	local prompt = drop:FindFirstChildWhichIsA("ProximityPrompt")
	if not prompt then
		return false
	end

	local deadline = os.clock() + 2.5
	while Automation.autoDroppedLootEnabled and drop.Parent and not prompt.Enabled and os.clock() < deadline do
		task.wait(0.03)
	end

	if not Automation.autoDroppedLootEnabled or not drop.Parent or not prompt.Enabled then
		return false
	end

	local _, _, rootPart = getCharacter()
	if not rootPart then
		return false
	end

	local target = drop:GetAttribute("DropTarget")
	local position = typeof(target) == "Vector3" and target or drop.Position
	rootPart.CFrame = CFrame.new(position + Vector3.new(0, 2.5, 0))
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	task.wait(0.04)

	if not triggerPrompt(prompt) then
		return false
	end

	local claimDeadline = os.clock() + 0.75
	while drop.Parent and drop:GetAttribute("DropClaimedBy") == nil and os.clock() < claimDeadline do
		task.wait(0.03)
	end

	return not drop.Parent or drop:GetAttribute("DropClaimedBy") == LocalPlayer.UserId
end

function Automation.runAutoDroppedLootLoop(generation)
	while Automation.autoDroppedLootEnabled and Automation.autoDroppedLootGeneration == generation do
		if safeRetreatActive or currentCombatTarget then
			task.wait(0.1)
			continue
		end

		local _, _, rootPart = getCharacter()
		if not rootPart then
			task.wait(0.15)
			continue
		end

		local returnCFrame = rootPart.CFrame
		local chest = Automation.getNearestUnlockedDroppedChest(rootPart.Position, 120)

		if chest then
			activateChest(chest)
			task.wait(0.25)
		end

		local collectedAny = false

		for _ = 1, 24 do
			if not Automation.autoDroppedLootEnabled or Automation.autoDroppedLootGeneration ~= generation then
				break
			end

			local drop = Automation.getNearestEligibleLootDrop(rootPart.Position, 160)
			if not drop then
				break
			end

			if Automation.collectEligibleLootDrop(drop) then
				collectedAny = true
			else
				break
			end

			task.wait(0.02)
		end

		if collectedAny and rootPart.Parent then
			rootPart.CFrame = returnCFrame
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero
		end

		task.wait((chest or collectedAny) and 0.05 or 0.15)
	end
end
local function getSealedChestGuardNames(chest)
	local identity = getChestIdentity(chest):lower()

	if identity:find("t1", 1, true) then
		return {"GroveRaider", "Grove Raider", "RaidCaptain", "Raid Captain"}
	end

	if identity:find("t2", 1, true) then
		return {"CacheLancer", "Cache Lancer", "LancerCaptain", "Lancer Captain"}
	end

	if identity:find("t3", 1, true) then
		return {"CacheProwler", "Cache Prowler", "ProwlerCaptain", "Prowler Captain"}
	end

	return {
		"GroveRaider",
		"Grove Raider",
		"RaidCaptain",
		"Raid Captain",
		"CacheLancer",
		"Cache Lancer",
		"LancerCaptain",
		"Lancer Captain",
		"CacheProwler",
		"Cache Prowler",
		"ProwlerCaptain",
		"Prowler Captain",
	}
end

local function findGuardNearChest(chest)
	local chestPosition = getWorldPosition(chest)
	if not chestPosition then
		return nil
	end

	local regions = workspace:FindFirstChild("Humanoids")
	regions = regions and regions:FindFirstChild("Regions")
	if not regions then
		return nil
	end

	local guardNames = getSealedChestGuardNames(chest)
	local nearestGuard
	local nearestDistance = math.huge

	for _, model in ipairs(regions:GetDescendants()) do
		if model:IsA("Model") then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local targetRoot = model:FindFirstChild("HumanoidRootPart")

			if humanoid and humanoid.Health > 0 and targetRoot then
				local matches = false

				for _, guardName in ipairs(guardNames) do
					if getNpcMatchScore(guardName, model.Name) > 0 or getNpcMatchScore(guardName, model.Parent and model.Parent.Name or "") > 0 then
						matches = true
						break
					end
				end

				if matches then
					local distance = (targetRoot.Position - chestPosition).Magnitude
					if distance <= 180 and distance < nearestDistance then
						nearestDistance = distance
						nearestGuard = model
					end
				end
			end
		end
	end

	return nearestGuard
end

local function runAutoChestLoop(generation)
	while autoChestEnabled and autoChestGeneration == generation do
		if safeRetreatActive then
			task.wait(0.2)
			continue
		end

		local _, _, rootPart = getCharacter()
		if not rootPart then
			task.wait(0.25)
			continue
		end

		local chest = getNearestChest(rootPart.Position, nil, true)
		if not chest then
			task.wait(0.75)
			continue
		end

		if chest:GetAttribute("ChestState") == "Locked" then
			local guard = findGuardNearChest(chest)

			if guard then
				fightStandaloneTarget(guard, generation, "Chest")
			else
				task.wait(0.25)
			end
		else
			activateChest(chest)
			task.wait(0.6)
		end
	end

	setBlocking(false)
end

local function getBossEntries()
	local success, entries = pcall(WorldBosses.Get)
	if success and type(entries) == "table" then
		return entries
	end

	return {}
end

local function getBossOptions()
	local options = {}

	for _, boss in ipairs(getBossEntries()) do
		if type(boss.Name) == "string" and boss.Name ~= "" then
			table.insert(options, boss.Name)
		end
	end

	table.sort(options)

	return options
end

local function getBossByName(name)
	for _, boss in ipairs(getBossEntries()) do
		if boss.Name == name then
			return boss
		end
	end

	return nil
end

local function openBossChest(originPosition)
	if typeof(originPosition) ~= "Vector3" then
		return
	end

	local deadline = os.clock() + 4

	while os.clock() < deadline and autoBossEnabled do
		local chest = getNearestChest(originPosition, 75, false)

		if chest and chest:GetAttribute("ChestState") ~= "Locked" then
			activateChest(chest)
			return
		end

		task.wait(0.2)
	end
end

local function runAutoBossLoop(generation)
	while autoBossEnabled and autoBossGeneration == generation do
		if safeRetreatActive then
			task.wait(0.2)
			continue
		end

		local boss = getBossByName(selectedBossName)
		if not boss then
			task.wait(0.5)
			continue
		end

		local target = getNearestNpc(boss.Code, boss.Position)
		if not target then
			target = getNearestNpc(boss.Name, boss.Position)
		end

		if target then
			local deathPosition = fightStandaloneTarget(target, generation, "Boss")
			if deathPosition and autoBossEnabled and autoBossGeneration == generation then
				openBossChest(deathPosition)
			end
		elseif typeof(boss.Position) == "Vector3" then
			moveToWorldPosition(boss.Position)
			openBossChest(boss.Position)
			task.wait(0.75)
		else
			task.wait(0.75)
		end
	end

	setBlocking(false)
end
function Automation.collectSkillTreeNodes(entries, output, seen)
	if type(entries) ~= "table" then
		return
	end

	for _, entry in ipairs(entries) do
		if type(entry) == "table" then
			if type(entry.Name) == "string" and entry.Name ~= "" and entry.IsBranch ~= true and not seen[entry.Name] then
				seen[entry.Name] = true
				table.insert(output, entry.Name)
			end

			if #entry > 0 then
				Automation.collectSkillTreeNodes(entry, output, seen)
			end
		end
	end
end

function Automation.getSkillTreeNodeOptions()
	local success, branches = pcall(SkillTreeHolder.GetBranches)
	if not success or type(branches) ~= "table" then
		return {}
	end

	local options = {}
	local seen = {}
	Automation.collectSkillTreeNodes(branches, options, seen)
	table.sort(options)

	return options
end

function Automation.getPowerSkillOptions(unlockedOnly)
	local success, powers = pcall(SkillTreeHolder.GetPowers, LocalPlayer)
	if not success or type(powers) ~= "table" then
		return {}
	end

	local options = {}
	local seen = {}

	for _, category in pairs(powers) do
		if type(category) == "table" then
			for _, power in ipairs(category) do
				if type(power) == "table" and type(power.Skills) == "table" then
					for _, skill in ipairs(power.Skills) do
						local skillName = type(skill) == "table" and skill.Name or nil

						if type(skillName) == "string" and skillName ~= "" and skillName ~= "Blocking" and not seen[skillName] then
							local include = true

							if unlockedOnly then
								local unlockedSuccess, unlocked = pcall(SkillTreeStats.IsSkillUnlocked, LocalPlayer, skillName)
								include = unlockedSuccess and unlocked == true
							end

							if include then
								seen[skillName] = true
								table.insert(options, skillName)
							end
						end
					end
				end
			end
		end
	end

	table.sort(options)

	return options
end

function Automation.runAutoSkillTreeLoop()
	while autoSkillTreeEnabled do
		if unlockSkillsFirst then
			for _, skillName in ipairs(Automation.getPowerSkillOptions(false)) do
				if not autoSkillTreeEnabled then
					return
				end

				local unlockedSuccess, unlocked = pcall(SkillTreeStats.IsSkillUnlocked, LocalPlayer, skillName)
				if not unlockedSuccess or unlocked ~= true then
					pcall(SignalFunction.ToServer, "UnlockSkillTreeNode", skillName)
					task.wait(0.15)
				end
			end
		end

		for _, nodeName in ipairs(selectedSkillTreeNodes) do
			if not autoSkillTreeEnabled then
				return
			end

			pcall(SignalFunction.ToServer, "UnlockSkillTreeNode", nodeName)
			task.wait(0.15)
		end

		task.wait(1.25)
	end
end

function Automation.getCraftRecipeOptions()
	local options = {}

	for recipeName in pairs(CraftingDefinitions) do
		if type(recipeName) == "string" and recipeName ~= "" then
			table.insert(options, recipeName)
		end
	end

	table.sort(options)

	return options
end

function Automation.findNearestCraftingTable()
	local _, _, rootPart = getCharacter()
	if not rootPart then
		return nil
	end

	local nearestTable
	local nearestDistance = math.huge

	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance.Name == "PS2 Crafting Table" and (instance:IsA("Model") or instance:IsA("BasePart")) then
			local position = getWorldPosition(instance)

			if position then
				local distance = (rootPart.Position - position).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearestTable = instance
				end
			end
		end
	end

	return nearestTable
end

function Automation.moveToCraftingTable()
	local craftingTable = Automation.findNearestCraftingTable()
	local position = getWorldPosition(craftingTable)

	if not position then
		return false
	end

	return moveToWorldPosition(position)
end

function Automation.runAutoCraftLoop()
	while autoCraftEnabled do
		if #selectedCraftRecipes > 0 and Automation.moveToCraftingTable() then
			for _, recipeName in ipairs(selectedCraftRecipes) do
				if not autoCraftEnabled then
					return
				end

				pcall(SignalFunction.ToServer, "CraftRecipe", recipeName)
				task.wait(0.3)
			end
		end

		task.wait(1)
	end
end

function Automation.getOwnedWeaponOptions()
	local inventory = getInventoryFolder()
	if not inventory then
		return {}
	end

	local options = {}
	local seen = {}

	for _, item in ipairs(inventory:GetChildren()) do
		local itemConfig = Items[item.Name]

		if itemConfig and (itemConfig.HasCombat == true or itemConfig.CombatPreset ~= nil or itemConfig.SkillCategory ~= nil) and not seen[item.Name] then
			seen[item.Name] = true
			table.insert(options, item.Name)
		end
	end

	table.sort(options)

	return options
end

function Automation.getItemIdentifier(item)
	if not item then
		return nil
	end

	local id = item:FindFirstChild("Id")
	if id and id:IsA("ValueBase") then
		return id.Value
	end

	return item:GetAttribute("Id")
end

Automation.toolbarSlotIndices = {
	One = 1,
	Two = 2,
	Three = 3,
	Four = 4,
	Five = 5,
}

function Automation.equipToolbarItem(itemName)
	local data = getPlayerData()
	local inventoryRoot = data and data:FindFirstChild("Inventory")
	local inventory = inventoryRoot and inventoryRoot:FindFirstChild("Inventory")
	local toolbar = inventoryRoot and inventoryRoot:FindFirstChild("Toolbar")
	local item = inventory and inventory:FindFirstChild(itemName)

	if not item or not toolbar then
		return nil
	end

	local itemId = Automation.getItemIdentifier(item)
	if itemId == nil then
		return nil
	end

	SignalEvent:FireServer("Toolbar_Equip", itemName, itemId)
	task.wait(0.2)

	local slotIndex

	for _, slot in ipairs(toolbar:GetChildren()) do
		if slot:IsA("ValueBase") and slot.Value == itemId then
			slotIndex = Automation.toolbarSlotIndices[slot.Name]
			break
		end
	end

	if not slotIndex then
		return nil
	end

	local itemsConfig = LocalPlayer:FindFirstChild("Items_Config")
	local equipped = itemsConfig and itemsConfig:FindFirstChild("Equipped")

	if equipped and equipped:IsA("ValueBase") then
		equipped.Value = slotIndex
	end

	SignalEvent:FireServer("Item_Equip", slotIndex)
	task.wait(0.15)

	return slotIndex
end

function Automation.equipSelectedWeapon()
	if not selectedWeaponName then
		return false
	end

	return Automation.equipToolbarItem(selectedWeaponName) ~= nil
end

function Automation.getPotionOptions()
	local inventory = getInventoryFolder()
	if not inventory then
		return {}
	end

	local options = {}
	local seen = {}

	for _, item in ipairs(inventory:GetChildren()) do
		local itemConfig = Items[item.Name]

		local isHealthPotion = item.Name == "Health Potion"
			or item.Name == "Health Elixir"
			or item.Name == "Health Regen Potion"
			or item.Name == "Health Regen Elixir"

		if itemConfig and isHealthPotion and not seen[item.Name] then
			seen[item.Name] = true
			table.insert(options, item.Name)
		end
	end

	table.sort(options)

	return options
end

function Automation.useSelectedPotion()
	if potionInUse or not selectedPotionName then
		return false
	end

	local inventory = getInventoryFolder()
	local item = inventory and inventory:FindFirstChild(selectedPotionName)

	if not item then
		return false
	end

	potionInUse = true
	local slotIndex = Automation.equipToolbarItem(selectedPotionName)

	if not slotIndex then
		potionInUse = false
		return false
	end

	local _, _, rootPart = getCharacter()
	local mousePosition = rootPart and rootPart.Position or Vector3.zero

	SignalEvent:FireServer("Tool_Mouse", "Down", mousePosition)
	task.wait(2)
	SignalEvent:FireServer("Tool_Mouse", "Up", mousePosition)
	potionInUse = false

	if selectedWeaponName then
		Automation.equipSelectedWeapon()
	end

	return true
end

function Automation.runAutoPotionLoop()
	while autoPotionEnabled do
		local currentHealth, maximumHealth = getDisplayedHealth()

		if currentHealth and maximumHealth and maximumHealth > 0 then
			local percentage = currentHealth / maximumHealth * 100

			if percentage <= potionHealthPercent then
				Automation.useSelectedPotion()
			end
		end

		task.wait(0.3)
	end
end

function Automation.unlockAllSchematics()
	local inventory = getInventoryFolder()
	if not inventory then
		return
	end

	local _, _, rootPart = getCharacter()
	if not rootPart then
		return
	end

	local returnCFrame = rootPart.CFrame

	for _, studyProp in ipairs(CollectionService:GetTagged("StudyProp")) do
		local itemName = studyProp:GetAttribute("Item")
		local schematicName = type(itemName) == "string" and itemName .. " Schematic" or nil

		if schematicName and studyProp:GetAttribute("Locked") ~= true and not inventory:FindFirstChild(schematicName) then
			local prompt = studyProp:FindFirstChildWhichIsA("ProximityPrompt", true)
			local position = getWorldPosition(studyProp)

			if prompt and position then
				rootPart.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
				rootPart.AssemblyLinearVelocity = Vector3.zero
				rootPart.AssemblyAngularVelocity = Vector3.zero
				task.wait(0.1)
				triggerPrompt(prompt)
				task.wait(0.25)
			end
		end
	end

	if rootPart.Parent then
		rootPart.CFrame = returnCFrame
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end
end

function Automation.getEquipmentScore(itemConfig)
	if not itemConfig or type(itemConfig.Stats) ~= "table" then
		return -math.huge
	end

	local score = 0

	for statName, statValue in pairs(itemConfig.Stats) do
		if type(statValue) == "number" then
			local name = tostring(statName):lower()
			local weight = 1

			if name:find("factor", 1, true) then
				weight = 1000
			elseif name:find("damage", 1, true) then
				weight = 25
			elseif name:find("regen", 1, true) then
				weight = 150
			elseif name:find("speed", 1, true) then
				weight = 100
			elseif name:find("max health", 1, true) then
				weight = 1
			elseif name:find("max stamina", 1, true) then
				weight = 0.6
			end

			score += statValue * weight
		end
	end

	score += (itemConfig.Rarity or 0) * 0.01

	return score
end

function Automation.autoEquipBestEquipment()
	local inventory = getInventoryFolder()
	if not inventory then
		return
	end

	local candidates = {}

	for _, item in ipairs(inventory:GetChildren()) do
		local itemConfig = Items[item.Name]
		local itemId = Automation.getItemIdentifier(item)

		if itemConfig
			and itemConfig.EquipType == Menum.ItemEquipType.Accessory
			and itemId ~= nil
			and type(itemConfig.Stats) == "table"
		then
			table.insert(candidates, {
				id = itemId,
				rarity = itemConfig.Rarity or 0,
				score = Automation.getEquipmentScore(itemConfig),
			})
		end
	end

	table.sort(candidates, function(left, right)
		if left.score == right.score then
			return left.rarity > right.rarity
		end
		return left.score > right.score
	end)

	local slots = {"One", "Two", "Three", "Four", "Five"}

	for index, slotName in ipairs(slots) do
		local candidate = candidates[index]
		SignalEvent:FireServer("AccessoryEquip", slotName, candidate and candidate.id or 0, "Stats")
		task.wait(0.08)
	end

	table.sort(candidates, function(left, right)
		if left.rarity == right.rarity then
			return left.score > right.score
		end
		return left.rarity > right.rarity
	end)

	for index, slotName in ipairs(slots) do
		local candidate = candidates[index]
		SignalEvent:FireServer("AccessoryEquip", slotName, candidate and candidate.id or 0, "Vanity")
		task.wait(0.08)
	end
end

function Automation.getTeleportZoneOptions()
	local options = {}

	for regionName in pairs(staticRegionPositions) do
		table.insert(options, regionName)
	end

	table.sort(options)

	return options
end

function Automation.getTeleportZonePosition(zoneName)
	return staticRegionPositions[zoneName]
end

function Automation.teleportToZone(zoneName)
	local position = Automation.getTeleportZonePosition(zoneName)
	if not position then
		return false
	end

	local _, _, rootPart = getCharacter()
	if not rootPart then
		return false
	end

	pcall(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, position, 3)
	rootPart.Anchored = true
	rootPart.CFrame = CFrame.new(position + Vector3.new(0, 4, 0))
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	task.wait(0.8)

	local map = workspace:FindFirstChild("Map")
	if map then
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = {map}
		local rayOrigin = Vector3.new(position.X, math.max(position.Y + 800, 3000), position.Z)
		local result = workspace:Raycast(rayOrigin, Vector3.new(0, -5000, 0), raycastParams)

		if result then
			rootPart.CFrame = CFrame.new(result.Position + Vector3.new(0, 4, 0))
		end
	end

	rootPart.Anchored = false

	return true
end

function Automation.setNoRagdollEnabled(enabled)
	local valuesRoot = ReplicatedStorage:FindFirstChild("Player_Service")
	valuesRoot = valuesRoot and valuesRoot:FindFirstChild("Values")
	local values = valuesRoot and valuesRoot:FindFirstChild(LocalPlayer.Name)

	if not values then
		return
	end

	for _, value in ipairs(values:GetChildren()) do
		if value.Name == "noragdoll" and value:GetAttribute("QuestFarmNoRagdoll") == true then
			value:Destroy()
		end
	end

	if enabled then
		local value = Instance.new("BoolValue")
		value.Name = "noragdoll"
		value:SetAttribute("QuestFarmNoRagdoll", true)
		value.Parent = values
	end
end

function Automation.runAutoSkillsLoop()
	while autoSkillsEnabled do
		local target = currentCombatTarget
		local humanoid = target and target:FindFirstChildOfClass("Humanoid")

		if target and target.Parent and humanoid and humanoid.Health > 0 then
			local skills = selectedAutoSkills
			if #skills == 0 then
				skills = Automation.getPowerSkillOptions(true)
			end

			for _, skillName in ipairs(skills) do
				if not autoSkillsEnabled then
					return
				end

				local currentHumanoid = target:FindFirstChildOfClass("Humanoid")
				if not target.Parent or not currentHumanoid or currentHumanoid.Health <= 0 then
					break
				end

				pcall(SkillController.Attempt_Hold, skillName)
				task.wait(0.12)
				pcall(SkillController.StopHold, skillName)
				task.wait(0.18)
			end
		end

		task.wait(0.35)
	end
end
function Automation.getFishingBaitOptions()
	local options = {"None"}
	local fishingItems = ReplicatedStorage:FindFirstChild("Items")
	fishingItems = fishingItems and fishingItems:FindFirstChild("Fishing")

	if fishingItems then
		for _, module in ipairs(fishingItems:GetChildren()) do
			if module:IsA("ModuleScript") then
				local success, config = pcall(require, module)
				if success and type(config) == "table" and config.BaitTier ~= nil then
					table.insert(options, module.Name)
				end
			end
		end
	end

	table.sort(options, function(left, right)
		if left == "None" then
			return true
		end
		if right == "None" then
			return false
		end
		return left:lower() < right:lower()
	end)

	return options
end

function Automation.getBestFishingRod()
	local inventory = getInventoryFolder()
	if not inventory then
		return nil
	end

	for _, rodName in ipairs({"Legendary Fishing Rod", "Rare Fishing Rod", "Basic Fishing Rod"}) do
		if inventory:FindFirstChild(rodName) then
			return rodName
		end
	end

	return nil
end

function Automation.completeFishingPermit()
	local inventory = getInventoryFolder()
	if not inventory then
		return false
	end

	if inventory:FindFirstChild("Fishing Permit") then
		return true
	end

	local questKey = "Ill find the permit stamp(Lv 45)"
	refreshQuestDefinitions()

	if not getActiveQuest(questKey) then
		cancelOtherActiveQuests(questKey)

		if not moveToQuestGiver(questKey) then
			return false
		end

		if not canTakeQuest(questKey) then
			return false
		end

		SignalEvent:FireServer("AddQuest", questKey)

		local deadline = os.clock() + 3
		while not getActiveQuest(questKey) and os.clock() < deadline do
			task.wait(0.1)
		end
	end

	local activeQuest = getActiveQuest(questKey)
	local definition = questDefinitions[questKey] or Quests.Holder[questKey]

	while autoFishEnabled and activeQuest and activeQuest.Parent do
		local questTask = getPendingQuestTask(activeQuest)
		if not questTask then
			break
		end

		local spec = getTaskSpec(definition, questTask.Name)
		if not spec then
			return false
		end

		if spec.Type == "Pickup" then
			local positions = spec.Positions or {}
			for slotIndex, position in ipairs(positions) do
				if not autoFishEnabled then
					return false
				end

				local value = questTask:FindFirstChild("Value")
				local maximum = questTask:FindFirstChild("Max")
				if value and maximum and value.Value >= maximum.Value then
					break
				end

				moveToWorldPosition(position)
				task.wait(0.15)
				SignalEvent:FireServer("QuestProgress", questKey, questTask.Name, slotIndex)
				task.wait(0.35)
			end
		elseif spec.Type == "Deliver" then
			if not moveToNamedNpc(spec.TargetNpc) then
				return false
			end

			SignalEvent:FireServer("QuestProgress", questKey, questTask.Name)
			task.wait(0.5)
		else
			return false
		end

		activeQuest = getActiveQuest(questKey)
	end

	local rewardDeadline = os.clock() + 4
	while autoFishEnabled and os.clock() < rewardDeadline do
		inventory = getInventoryFolder()
		if inventory and inventory:FindFirstChild("Fishing Permit") then
			return true
		end
		task.wait(0.1)
	end

	return false
end

function Automation.ensureFishingRod()
	local rodName = Automation.getBestFishingRod()
	if rodName then
		return rodName
	end

	if not Automation.completeFishingPermit() then
		return nil
	end

	if not moveToNamedNpc("Fisherman Jeso") then
		return nil
	end

	SignalEvent:FireServer("PurchaseFromShop", "Basic Fishing Rod", 1)

	local deadline = os.clock() + 4
	while autoFishEnabled and os.clock() < deadline do
		rodName = Automation.getBestFishingRod()
		if rodName then
			return rodName
		end
		task.wait(0.1)
	end

	return nil
end

function Automation.getFishingBaitItem()
	if selectedFishingBait == "None" then
		return nil
	end

	local inventory = getInventoryFolder()
	return inventory and inventory:FindFirstChild(selectedFishingBait)
end

function Automation.buyFishingBait()
	if selectedFishingBait == "None" then
		return true
	end

	local npcName
	local shopItemName = selectedFishingBait

	if selectedFishingBait == "Worm" then
		npcName = "Fisherman Jeso"
	elseif selectedFishingBait == "Fish Head" then
		npcName = "Baitmonger Nori"
	elseif selectedFishingBait == "Golden Tentacle" then
		npcName = "Baitmonger Nori"
		shopItemName = "Golden Tentacle x10"
	else
		return false
	end

	if not moveToNamedNpc(npcName) then
		return false
	end

	SignalEvent:FireServer("PurchaseFromShop", shopItemName, 1)

	local deadline = os.clock() + 3
	while autoFishEnabled and os.clock() < deadline do
		if Automation.getFishingBaitItem() then
			return true
		end
		task.wait(0.1)
	end

	return false
end

function Automation.equipFishingBait()
	if selectedFishingBait == "None" then
		SignalEvent:FireServer("EquipBait", 0)
		return true
	end

	local item = Automation.getFishingBaitItem()

	if not item and autoBuyBaitEnabled then
		if not Automation.buyFishingBait() then
			return false
		end
		item = Automation.getFishingBaitItem()
	end

	if not item then
		return false
	end

	local itemId = Automation.getItemIdentifier(item)
	if itemId == nil then
		return false
	end

	SignalEvent:FireServer("EquipBait", itemId)
	task.wait(0.15)

	return true
end

function Automation.getClosestFishingWater()
	local _, _, rootPart = getCharacter()
	if not rootPart then
		return nil, nil
	end

	local bestPart
	local bestPoint
	local bestDistance = math.huge

	for _, instance in ipairs(CollectionService:GetTagged("SwimParts")) do
		local part = instance

		if not part:IsA("BasePart") then
			part = instance:FindFirstChild("TouchPart", true) or instance:FindFirstChildWhichIsA("BasePart", true)
		end

		if part and part:IsA("BasePart") then
			local localPoint = part.CFrame:PointToObjectSpace(rootPart.Position)
			local halfSize = part.Size * 0.5
			local x = math.clamp(localPoint.X, -halfSize.X, halfSize.X)
			local z = math.clamp(localPoint.Z, -halfSize.Z, halfSize.Z)
			local point = part.CFrame:PointToWorldSpace(Vector3.new(x, halfSize.Y, z))
			local distance = (Vector3.new(point.X, rootPart.Position.Y, point.Z) - rootPart.Position).Magnitude

			if distance < bestDistance then
				bestDistance = distance
				bestPart = part
				bestPoint = point
			end
		end
	end

	return bestPart, bestPoint
end

function Automation.moveToFishingPosition()
	local waterPart, waterPoint = Automation.getClosestFishingWater()
	if not waterPart or not waterPoint then
		return nil
	end

	local _, _, rootPart = getCharacter()
	if not rootPart then
		return nil
	end

	local center = waterPart.Position
	local away = Vector3.new(waterPoint.X - center.X, 0, waterPoint.Z - center.Z)

	if away.Magnitude < 0.1 then
		away = Vector3.new(
			rootPart.Position.X - center.X,
			0,
			rootPart.Position.Z - center.Z
		)
	end

	if away.Magnitude < 0.1 then
		away = Vector3.new(1, 0, 0)
	end

	away = away.Unit
	local standPosition = waterPoint + away * 7
	local raycastParams = RaycastParams.new()
	local map = workspace:FindFirstChild("Map")

	if map then
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = {map}
	end

	local rayOrigin = standPosition + Vector3.new(0, 100, 0)
	local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -250, 0), raycastParams)

	if rayResult then
		standPosition = rayResult.Position + Vector3.new(0, 3, 0)
	else
		standPosition = Vector3.new(standPosition.X, rootPart.Position.Y, standPosition.Z)
	end

	rootPart.CFrame = CFrame.lookAt(standPosition, waterPoint)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	task.wait(0.15)

	return waterPoint + Vector3.new(0, 0.5, 0)
end

function Automation.destroyFishingPortal()
	if fishingPortal and fishingPortal.__Active then
		fishingPortal:Destroy()
	end
	fishingPortal = nil
end

function Automation.createFishingPortal()
	Automation.destroyFishingPortal()

	local portal = ServerClientPortal.Link("FishingRod", -1)
	fishingPortal = portal

	portal:Connect(function(action, token)
		if not autoFishEnabled or fishingPortal ~= portal then
			return
		end

		if action == "Bite" and token ~= nil then
			fishingBiteSequence += 1
			portal:Server(token, true)
		end
	end)

	return portal
end

function Automation.runAutoFishLoop()
	while autoFishEnabled do
		local rodName = Automation.ensureFishingRod()

		if not rodName then
			task.wait(1)
			continue
		end

		local slotIndex = Automation.equipToolbarItem(rodName)
		if not slotIndex then
			task.wait(0.5)
			continue
		end

		task.wait(0.25)
		Automation.createFishingPortal()

		if not Automation.equipFishingBait() and selectedFishingBait ~= "None" then
			task.wait(0.75)
			continue
		end

		local castPosition = Automation.moveToFishingPosition()
		if not castPosition then
			task.wait(0.75)
			continue
		end

		local biteBefore = fishingBiteSequence
		SignalEvent:FireServer("Tool_Mouse", "Up", castPosition)

		local deadline = os.clock() + 16
		while autoFishEnabled and fishingBiteSequence == biteBefore and os.clock() < deadline do
			task.wait(0.1)
		end

		task.wait(1.25)
	end

	Automation.destroyFishingPortal()

	if selectedWeaponName then
		Automation.equipSelectedWeapon()
	else
		SignalEvent:FireServer("Item_Equip", 0)
	end
end
function Automation.getBreathingQuestMap()
	return {
		Flame = "Ill learn Flame Breathing(Lv 25)",
		Thunder = "Ill learn Thunder Breathing(Lv 25)",
		Water = "Ill learn Water Breathing(Lv 25)",
		Wind = "Ill learn Wind Breathing(Lv 25)",
		Stone = "Ill learn Stone Breathing(Lv 25)",
		Serpent = "Ill learn Serpent Breathing(Lv 25)",
		Insect = "Ill learn Insect Breathing(Lv 25)",
		Sound = "Ill learn Sound Breathing(Lv 25)",
	}
end

function Automation.getBreathingOptions()
	refreshQuestDefinitions()

	local options = {}
	local data = getPlayerData()
	local currentBreathing = data and data:FindFirstChild("Powers") and data.Powers:FindFirstChild("Breathing")

	for breathingName, questKey in pairs(Automation.getBreathingQuestMap()) do
		local definition = questDefinitions[questKey] or Quests.Holder[questKey]
		if definition and (not currentBreathing or currentBreathing.Value == "" or currentBreathing.Value == breathingName) then
			local hasAccess = true
			local success, result = pcall(CharacterInfoProvider.HasPowerAccess, LocalPlayer, breathingName)
			if success then
				hasAccess = result == true
			end

			if hasAccess then
				table.insert(options, breathingName)
			end
		end
	end

	table.sort(options)

	return options
end

function Automation.getTrainingType(task)
	local name = task and task.Name or ""
	local code = task and task:FindFirstChild("Code")
	local codeValue = code and code.Value or nil

	local aliases = {
		["Meditate"] = "Meditation",
		["Push ups"] = "Pushups",
		["Barbell squats"] = "Squat",
		["Aim Training"] = "Target Shooting",
		["Cup Training"] = "Cup Game",
		["Boulder Split"] = "Boulder Split",
		["Boulder Push"] = "Boulder Push",
		["Parkour Dungeon"] = "Parkour Dungeon",
	}

	if aliases[name] then
		return aliases[name]
	end

	if type(codeValue) == "string" and codeValue ~= "" then
		if aliases[codeValue] then
			return aliases[codeValue]
		end

		if ReplicatedStorage.CAM.Global.Training:FindFirstChild(codeValue) then
			return codeValue
		end
	end

	return nil
end

function Automation.findTrainingPrompt(trainingType)
	local _, _, rootPart = getCharacter()
	if not rootPart then
		return nil
	end

	local bestPrompt
	local bestDistance = math.huge
	local searchTerms = {
		trainingType:lower(),
	}

	if trainingType == "Meditation" then
		table.insert(searchTerms, "meditate")
	elseif trainingType == "Pushups" then
		table.insert(searchTerms, "push ups")
	elseif trainingType == "Squat" then
		table.insert(searchTerms, "squat")
		table.insert(searchTerms, "barbell")
	elseif trainingType == "Target Shooting" then
		table.insert(searchTerms, "aim training")
		table.insert(searchTerms, "target shooting")
	elseif trainingType == "Cup Game" then
		table.insert(searchTerms, "cup training")
	end

	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			local text = (descendant.ObjectText .. " " .. descendant.ActionText .. " " .. descendant:GetFullName()):lower()
			local matches = false

			for _, term in ipairs(searchTerms) do
				if text:find(term, 1, true) then
					matches = true
					break
				end
			end

			if matches then
				local parent = descendant.Parent
				local position

				if parent and parent:IsA("BasePart") then
					position = parent.Position
				elseif parent and parent:IsA("Model") then
					position = parent:GetPivot().Position
				elseif parent and parent.Parent and parent.Parent:IsA("Model") then
					position = parent.Parent:GetPivot().Position
				end

				if position then
					local distance = (rootPart.Position - position).Magnitude
					if distance < bestDistance then
						bestDistance = distance
						bestPrompt = descendant
					end
				end
			end
		end
	end

	return bestPrompt
end

function Automation.getTrainingValue()
	local values = Utility.getvaluesfolder(LocalPlayer)
	return values and values:FindFirstChild("Training") or nil
end

function Automation.startTraining(trainingType)
	local prompt = Automation.findTrainingPrompt(trainingType)
	if not prompt then
		return nil
	end

	local position = getWorldPosition(prompt.Parent)
	if not position and prompt.Parent and prompt.Parent.Parent then
		position = getWorldPosition(prompt.Parent.Parent)
	end

	if position then
		moveToWorldPosition(position)
		task.wait(0.15)
	end

	triggerPrompt(prompt)

	local deadline = os.clock() + 5
	while autoBreathingEnabled and os.clock() < deadline do
		local training = Automation.getTrainingValue()
		if training and training:GetAttribute("Type") == trainingType then
			return training
		end
		task.wait(0.1)
	end

	return nil
end

function Automation.waitForTrainingEnd(training, timeout)
	local deadline = os.clock() + (timeout or 5)

	while autoBreathingEnabled and training and training.Parent and os.clock() < deadline do
		task.wait(0.1)
	end

	return not training or not training.Parent
end
function Automation.completeParkourTraining(training)
	local map = workspace:FindFirstChild("Map")
	map = map and map:FindFirstChild("DetachedMaps")
	map = map and map:FindFirstChild("ParkourTraining")
	if not map then
		return false
	end

	local _, _, rootPart = getCharacter()
	if not rootPart then
		return false
	end

	local switches = map:FindFirstChild("Switchs")
	if switches then
		for _, switchModel in ipairs(switches:GetChildren()) do
			if not autoBreathingEnabled or not training.Parent then
				return false
			end

			local position = getWorldPosition(switchModel)
			if position then
				rootPart.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
				rootPart.AssemblyLinearVelocity = Vector3.zero
				rootPart.AssemblyAngularVelocity = Vector3.zero
				task.wait(0.12)
				SignalEvent:FireServer("training_signaler", "StateChanged", switchModel)
				task.wait(0.1)
			end
		end
	end

	local final = map:FindFirstChild("Final")
	if not final or not final:IsA("BasePart") then
		return false
	end

	rootPart.CFrame = final.CFrame * CFrame.new(0, 4, 0)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	task.wait(0.15)
	SignalEvent:FireServer("training_signaler", "Stop")

	return Automation.waitForTrainingEnd(training, 3)
end

function Automation.completeBoulderPushTraining(training)
	SignalEvent:FireServer("training_signaler", "StateChanged", true)
	task.wait(0.15)

	local goalPosition = training:GetAttribute("GoalPosition")
	if typeof(goalPosition) ~= "Vector3" then
		return false
	end

	local _, _, rootPart = getCharacter()
	if not rootPart then
		return false
	end

	for _ = 1, 4 do
		if not autoBreathingEnabled or not training.Parent then
			break
		end

		rootPart.CFrame = CFrame.new(goalPosition + Vector3.new(0, 2, 0))
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		task.wait(0.25)
	end

	if training.Parent then
		SignalEvent:FireServer("training_signaler", "Stop")
	end

	return Automation.waitForTrainingEnd(training, 2)
end

function Automation.completeTraining(trainingType, training)
	if trainingType == "Parkour Dungeon" then
		return Automation.completeParkourTraining(training)
	end

	if trainingType == "Boulder Push" then
		return Automation.completeBoulderPushTraining(training)
	end

	SignalEvent:FireServer("training_signaler", "Stop", true)

	local timeout = trainingType == "Boulder Split" and 14 or 4
	return Automation.waitForTrainingEnd(training, timeout)
end

function Automation.completeBreathingPickupTask(questKey, task, spec)
	local positions = spec and spec.Positions
	if type(positions) ~= "table" then
		return false
	end

	for slotIndex, position in ipairs(positions) do
		if not autoBreathingEnabled then
			return false
		end

		local value = task:FindFirstChild("Value")
		local maximum = task:FindFirstChild("Max")
		if value and maximum and value.Value >= maximum.Value then
			return true
		end

		if moveToWorldPosition(position) then
			task.wait(0.15)
			SignalEvent:FireServer("QuestProgress", questKey, task.Name, slotIndex)
			task.wait(0.25)
		end
	end

	local value = task:FindFirstChild("Value")
	local maximum = task:FindFirstChild("Max")
	return value and maximum and value.Value >= maximum.Value or false
end

function Automation.hasTrainerCost(definition)
	if type(definition.ItemCostOnAccept) ~= "table" then
		return true
	end

	for itemName, amount in pairs(definition.ItemCostOnAccept) do
		if getInventoryItemAmount(itemName) < amount then
			return false
		end
	end

	return true
end

function Automation.completeBreathingTask(questKey, definition, activeQuest, task, generation)
	local spec = getTaskSpec(definition, task.Name)

	if spec and spec.Type == "Pickup" then
		return Automation.completeBreathingPickupTask(questKey, task, spec)
	end

	if spec and spec.Type == "Dungeon" then
		local trainingType = spec.Dungeon or "Parkour Dungeon"
		local training = Automation.startTraining(trainingType)
		if not training then
			return false
		end
		return Automation.completeTraining(trainingType, training)
	end

	if task.Name:sub(1, 11) == "Defeat the " then
		local code = task:FindFirstChild("Code")
		local npcCode = code and code.Value or nil
		local position = getQuestPosition(questKey, task)
		local target = npcCode and getNearestNpc(npcCode, position) or nil

		if not target then
			if position then
				moveToQuestArea(position)
			end
			return false
		end

		fightStandaloneTarget(target, generation, "Breathing")

		local value = task:FindFirstChild("Value")
		local maximum = task:FindFirstChild("Max")
		return value and maximum and value.Value >= maximum.Value or false
	end

	local trainingType = Automation.getTrainingType(task)
	if not trainingType then
		return false
	end

	local training = Automation.startTraining(trainingType)
	if not training then
		return false
	end

	return Automation.completeTraining(trainingType, training)
end

function Automation.runAutoBreathingLoop(generation)
	local questMap = Automation.getBreathingQuestMap()

	while autoBreathingEnabled and autoBreathingGeneration == generation do
		local breathingName = selectedBreathingName
		local questKey = breathingName and questMap[breathingName] or nil

		if not questKey then
			task.wait(0.5)
			continue
		end

		local data = getPlayerData()
		local powers = data and data:FindFirstChild("Powers")
		local breathing = powers and powers:FindFirstChild("Breathing")

		if breathing and breathing.Value == breathingName then
			autoBreathingEnabled = false
			break
		end

		refreshQuestDefinitions()
		local definition = questDefinitions[questKey] or Quests.Holder[questKey]

		if not definition or not Automation.hasTrainerCost(definition) then
			task.wait(1)
			continue
		end

		local activeQuest = getActiveQuest(questKey)

		if not activeQuest then
			cancelOtherActiveQuests(questKey)

			if not moveToQuestGiver(questKey) then
				task.wait(0.75)
				continue
			end

			if not canTakeQuest(questKey) then
				task.wait(1)
				continue
			end

			SignalEvent:FireServer("AddQuest", questKey)

			local deadline = os.clock() + 3
			while autoBreathingEnabled and autoBreathingGeneration == generation and not getActiveQuest(questKey) and os.clock() < deadline do
				task.wait(0.1)
			end

			activeQuest = getActiveQuest(questKey)
		end

		if not activeQuest then
			task.wait(0.5)
			continue
		end

		local task = getPendingQuestTask(activeQuest)
		if not task then
			task.wait(0.5)
			continue
		end

		Automation.completeBreathingTask(questKey, definition, activeQuest, task, generation)
		task.wait(0.2)
	end

	setBlocking(false)
end

function Automation.getGuiText(instance)
	local parts = {instance.Name}

	if instance:IsA("TextButton") or instance:IsA("TextLabel") or instance:IsA("TextBox") then
		table.insert(parts, instance.Text)
	end

	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("TextButton") or descendant:IsA("TextLabel") or descendant:IsA("TextBox") then
			table.insert(parts, descendant.Text)
		end
	end

	local parent = instance.Parent
	for _ = 1, 4 do
		if not parent then
			break
		end
		table.insert(parts, parent.Name)
		parent = parent.Parent
	end

	return table.concat(parts, " "):lower()
end

function Automation.isGuiVisible(instance)
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	local current = instance

	while current and current ~= playerGui do
		if current:IsA("GuiObject") and current.Visible == false then
			return false
		end

		if current:IsA("ScreenGui") and current.Enabled == false then
			return false
		end

		current = current.Parent
	end

	return true
end

function Automation.activateGuiButton(button)
	if not button or not button:IsA("GuiButton") or not Automation.isGuiVisible(button) then
		return false
	end

	local fireSignal = rawget(getfenv(), "firesignal")
	if type(fireSignal) == "function" then
		local success = pcall(fireSignal, button.Activated)
		if success then
			return true
		end

		success = pcall(fireSignal, button.MouseButton1Click)
		if success then
			return true
		end
	end

	local success, virtualInput = pcall(game.GetService, game, "VirtualInputManager")
	if success and virtualInput then
		local position = button.AbsolutePosition + button.AbsoluteSize * 0.5
		local pressed = pcall(virtualInput.SendMouseButtonEvent, virtualInput, position.X, position.Y, 0, true, game, 0)
		if pressed then
			pcall(virtualInput.SendMouseButtonEvent, virtualInput, position.X, position.Y, 0, false, game, 0)
			return true
		end
	end

	return false
end
function Automation.scoreDungeonChoice(button)
	local text = Automation.getGuiText(button)
	local score = 0
	local currentHealth, maximumHealth = getDisplayedHealth()
	local lowHealth = currentHealth and maximumHealth and maximumHealth > 0 and currentHealth / maximumHealth < 0.5

	if lowHealth and text:find("heal", 1, true) then
		score += 10000
	end

	if Automation.dungeonRewardFocus == "Points" then
		if text:find("point", 1, true) or text:find("score", 1, true) then
			score += 9000
		end
		if text:find("fortune", 1, true) then
			score += 5000
		end
		if text:find("stat", 1, true) then
			score += 3200
		end
	else
		if text:find("revive", 1, true) then
			score += 9000
		end
		if text:find("life", 1, true) then
			score += 8200
		end
		if text:find("stat", 1, true) then
			score += 6500
		end
		if text:find("heal", 1, true) then
			score += 5600
		end
		if text:find("potion", 1, true) then
			score += 4200
		end
		if text:find("weapon", 1, true) or text:find("skill", 1, true) then
			score += 3200
		end
		if text:find("point", 1, true) or text:find("score", 1, true) then
			score += 1800
		end
	end

	return score
end
function Automation.getDungeonChoiceButtons()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return {}
	end

	local strict = {}
	local fallback = {}
	local words = {
		"heal",
		"point",
		"score",
		"skill",
		"stat",
		"weapon",
		"potion",
		"reroll",
		"life",
		"revive",
		"fortune",
		"trade",
		"clan",
		"forge",
		"swap",
	}

	for _, descendant in ipairs(playerGui:GetDescendants()) do
		if descendant:IsA("GuiButton") and descendant.Active and Automation.isGuiVisible(descendant) then
			local text = Automation.getGuiText(descendant)
			local matches = false

			for _, word in ipairs(words) do
				if text:find(word, 1, true) then
					matches = true
					break
				end
			end

			if matches then
				table.insert(fallback, descendant)

				if text:find("card", 1, true)
					or text:find("hand", 1, true)
					or text:find("choice", 1, true)
					or text:find("pick", 1, true)
				then
					table.insert(strict, descendant)
				end
			end
		end
	end

	if #strict > 0 then
		return strict
	end

	return fallback
end

function Automation.pickDungeonChoice()
	if not Automation.isDungeonPlace() or os.clock() - Automation.lastDungeonChoiceClick < 0.6 then
		return false
	end

	local bestButton
	local bestScore = 0

	for _, button in ipairs(Automation.getDungeonChoiceButtons()) do
		local score = Automation.scoreDungeonChoice(button)
		if score > bestScore then
			bestScore = score
			bestButton = button
		end
	end

	if not bestButton or bestScore <= 0 then
		return false
	end

	return Automation.activateGuiButton(bestButton)
end
function Automation.clickDungeonReady()
	if not Automation.isDungeonPlace() then
		return false
	end

	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return false
	end

	for _, descendant in ipairs(playerGui:GetDescendants()) do
		if descendant:IsA("GuiButton") and descendant.Active and Automation.isGuiVisible(descendant) then
			local text = Automation.getGuiText(descendant)

			if text:find("ready", 1, true) or text:find("skip", 1, true) then
				return Automation.activateGuiButton(descendant)
			end
		end
	end

	return false
end

function Automation.runDungeonUiLoop(generation)
	while Automation.dungeonUiGeneration == generation and Automation.isDungeonPlace() do
		if not Automation.autoPickDungeonRewards and not Automation.autoDungeonReady then
			break
		end

		if Automation.autoPickDungeonRewards then
			Automation.pickDungeonChoice()
		end

		if Automation.autoDungeonReady then
			Automation.clickDungeonReady()
		end

		task.wait(0.2)
	end
end
local function loadRayfield()
	local source = game:HttpGet("https://sirius.menu/gen2")
	local chunk = assert(loadstring(source))
	local environment = getfenv(chunk)
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local getPlayerGui = function()
		return playerGui
	end

	environment.gethui = getPlayerGui
	environment.get_hidden_ui = getPlayerGui
	environment.gethiddenui = getPlayerGui
	environment.protectgui = function()
	end

	if type(environment.syn) == "table" then
		local synEnvironment = table.clone(environment.syn)
		synEnvironment.protect_gui = function()
		end
		environment.syn = synEnvironment
	end

	setfenv(chunk, environment)

	return chunk()
end

local Rayfield = loadRayfield()

local window = Rayfield:CreateWindow({
	name = "moon",
	subtitle = "beta",
	sidebarLayout = true,
})

local farmTab = window:CreateTab({
	name = "Farm",
	icon = 93364949241311,
})
local questDropdown
local questFarmToggle
local mobDropdown
local mobFarmToggle
local bossDropdown
local autoBossToggle
local autoChestToggle
local autoBreathingToggle
local safeHealthSlider
local safeDebugStat
local safeHealthSliderCreating = false
local safeHealthMaximum = 1
Automation.automationTab = window:CreateTab({
	name = "Automation",
	icon = 7733954760,
})

Automation.utilityTab = window:CreateTab({
	name = "Utility",
	icon = 7734053495,
})
Automation.movementTab = window:CreateTab({
	name = "Movement",
	icon = 7734053495,
})

Automation.playerCombatTab = window:CreateTab({
	name = "Player Combat",
	icon = 7733954760,
})
if Automation.isDungeonPlace() then
	Automation.dungeonTab = window:CreateTab({
		name = "Dungeon",
		icon = 7733954760,
	})

	Automation.dungeonToggle = Automation.dungeonTab:CreateToggle({
		name = "Auto Dungeon",
		description = "Farms every enemy on each floor using farm positioning and combat automation",
		value = false,
		forgetState = true,
		callback = function(value)
			if value and not Automation.autoDungeonEnabled then
				Automation.stopOtherFarmModes("Dungeon")
			end

			Automation.autoDungeonEnabled = value
			Automation.autoDungeonGeneration += 1
			combatCombo = 1
			lastCombatAttack = 0
			nextCombatAttack = 0
			setBlocking(false)

			if value then
				task.spawn(Automation.runAutoDungeonLoop, Automation.autoDungeonGeneration)
			end
		end,
	})

	Automation.dungeonTab:CreateToggle({
		name = "Auto Pick Rewards",
		description = "Picks a reward as soon as the choice appears",
		value = false,
		forgetState = true,
		callback = function(value)
			Automation.autoPickDungeonRewards = value
			Automation.dungeonUiGeneration += 1

			if Automation.autoPickDungeonRewards or Automation.autoDungeonReady then
				task.spawn(Automation.runDungeonUiLoop, Automation.dungeonUiGeneration)
			end
		end,
	})

	Automation.dungeonTab:CreateDropdown({
		name = "Reward Focus",
		description = "Survival favors lives and stats, Points favors score rewards",
		options = {"Survival", "Points"},
		value = Automation.dungeonRewardFocus,
		forgetState = true,
		callback = function(value)
			Automation.dungeonRewardFocus = value or "Survival"
		end,
	})

	Automation.dungeonTab:CreateToggle({
		name = "Auto Skip / Ready",
		description = "Votes to skip wave breaks and starts the next floor",
		value = false,
		forgetState = true,
		callback = function(value)
			Automation.autoDungeonReady = value
			Automation.dungeonUiGeneration += 1

			if Automation.autoPickDungeonRewards or Automation.autoDungeonReady then
				task.spawn(Automation.runDungeonUiLoop, Automation.dungeonUiGeneration)
			end
		end,
	})
end

Automation.flyToggle = Automation.movementTab:CreateToggle({
	name = "Fly",
	description = "Free movement in any direction",
	value = false,
	forgetState = true,
	callback = function(value)
		Automation.flyEnabled = value
	end,
})

Automation.movementTab:CreateSlider({
	name = "Fly Speed",
	description = "Movement speed while flying",
	range = {10, 500},
	increment = 5,
	value = Automation.flySpeed,
	suffix = " studs/s",
	forgetState = true,
	callback = function(value)
		Automation.flySpeed = math.clamp(value, 10, 500)
	end,
})
Automation.noclipToggle = Automation.movementTab:CreateToggle({
	name = "Noclip",
	description = "Walk through walls and objects",
	value = false,
	forgetState = true,
	callback = function(value)
		Automation.manualNoclipEnabled = value
	end,
})

Automation.speedToggle = Automation.movementTab:CreateToggle({
	name = "Speed",
	description = "Moves by velocity instead of walkspeed",
	value = false,
	forgetState = true,
	callback = function(value)
		Automation.speedEnabled = value
	end,
})

Automation.movementTab:CreateSlider({
	name = "Walk Speed",
	description = "Movement speed while Speed is on",
	range = {16, 300},
	increment = 1,
	value = Automation.walkSpeed,
	suffix = " studs/s",
	forgetState = true,
	callback = function(value)
		Automation.walkSpeed = math.clamp(value, 16, 300)
	end,
})
Automation.highJumpToggle = Automation.movementTab:CreateToggle({
	name = "High Jump",
	description = "Higher jump",
	value = false,
	forgetState = true,
	callback = function(value)
		Automation.highJumpEnabled = value
	end,
})

Automation.movementTab:CreateSlider({
	name = "Jump Power",
	description = "Vertical jump speed",
	range = {50, 500},
	increment = 5,
	value = Automation.jumpPower,
	suffix = " studs/s",
	forgetState = true,
	callback = function(value)
		Automation.jumpPower = math.clamp(value, 50, 500)
	end,
})
Automation.skillNodeDropdown = Automation.automationTab:CreateDropdown({
	name = "Select Nodes",
	description = "Nodes to put skill points into",
	options = Automation.getSkillTreeNodeOptions(),
	multiSelect = true,
	value = selectedSkillTreeNodes,
	forgetState = true,
	callback = function(value)
		selectedSkillTreeNodes = value
	end,
})

Automation.automationTab:CreateToggle({
	name = "Unlock Skills",
	description = "Unlocks available weapon, breathing, demon art and clan skills first",
	value = false,
	forgetState = true,
	callback = function(value)
		unlockSkillsFirst = value
	end,
})

Automation.automationTab:CreateToggle({
	name = "Auto Skill Tree",
	description = "Spends skill points on the selected nodes",
	value = false,
	forgetState = true,
	callback = function(value)
		autoSkillTreeEnabled = value
		if value then
			task.spawn(Automation.runAutoSkillTreeLoop)
		end
	end,
})

Automation.recipeDropdown = Automation.automationTab:CreateDropdown({
	name = "Select Recipes",
	description = "Recipes are crafted in the order selected",
	options = Automation.getCraftRecipeOptions(),
	multiSelect = true,
	value = selectedCraftRecipes,
	forgetState = true,
	callback = function(value)
		selectedCraftRecipes = value
	end,
})

Automation.automationTab:CreateToggle({
	name = "Auto Craft",
	description = "Travels to the nearest crafting table and crafts selected recipes",
	value = false,
	forgetState = true,
	callback = function(value)
		autoCraftEnabled = value
		if value then
			task.spawn(Automation.runAutoCraftLoop)
		end
	end,
})

Automation.weaponDropdown = Automation.automationTab:CreateDropdown({
	name = "Select Weapon",
	description = "Owned weapon used by every combat farm",
	options = Automation.getOwnedWeaponOptions(),
	placeholder = "Select weapon",
	forgetState = true,
	callback = function(value)
		selectedWeaponName = value
		if value then
			task.spawn(Automation.equipSelectedWeapon)
		end
	end,
})

Automation.skillDropdown = Automation.automationTab:CreateDropdown({
	name = "Skills To Use",
	description = "Uses every unlocked skill when nothing is selected",
	options = Automation.getPowerSkillOptions(true),
	multiSelect = true,
	value = selectedAutoSkills,
	forgetState = true,
	callback = function(value)
		selectedAutoSkills = value
	end,
})

Automation.automationTab:CreateToggle({
	name = "Auto Skills",
	description = "Casts unlocked skills while a farm has a combat target",
	value = false,
	forgetState = true,
	callback = function(value)
		autoSkillsEnabled = value
		if value then
			task.spawn(Automation.runAutoSkillsLoop)
		end
	end,
})

Automation.potionDropdown = Automation.automationTab:CreateDropdown({
	name = "Select Potion",
	description = "Health potion used by Auto Potion",
	options = Automation.getPotionOptions(),
	placeholder = "Select potion",
	forgetState = true,
	callback = function(value)
		selectedPotionName = value
	end,
})

Automation.automationTab:CreateSlider({
	name = "Drink Below",
	description = "Drinks once health falls under this percentage",
	range = {5, 95},
	increment = 1,
	value = potionHealthPercent,
	suffix = "%",
	forgetState = true,
	callback = function(value)
		potionHealthPercent = math.clamp(value, 5, 95)
	end,
})

Automation.automationTab:CreateToggle({
	name = "Auto Potion",
	description = "Uses the selected health potion when health drops",
	value = false,
	forgetState = true,
	callback = function(value)
		autoPotionEnabled = value
		if value then
			task.spawn(Automation.runAutoPotionLoop)
		end
	end,
})
Automation.baitDropdown = Automation.automationTab:CreateDropdown({
	name = "Bait",
	description = "Fishing bait, None disables bait",
	options = Automation.getFishingBaitOptions(),
	value = selectedFishingBait,
	forgetState = true,
	callback = function(value)
		selectedFishingBait = value or "None"
		if autoFishEnabled then
			task.spawn(Automation.equipFishingBait)
		end
	end,
})

Automation.automationTab:CreateToggle({
	name = "Auto Buy Bait",
	description = "Buys more of the selected bait when you run out",
	value = false,
	forgetState = true,
	callback = function(value)
		autoBuyBaitEnabled = value
	end,
})

Automation.automationTab:CreateToggle({
	name = "Auto Fish",
	description = "Gets the fishing permit and a rod if needed, fishes at water and always lands the bite",
	value = false,
	forgetState = true,
	callback = function(value)
		autoFishEnabled = value

		if value then
			task.spawn(Automation.runAutoFishLoop)
		else
			Automation.destroyFishingPortal()
			if selectedWeaponName then
				task.spawn(Automation.equipSelectedWeapon)
			end
		end
	end,
})

Automation.automationTab:CreateToggle({
	name = "Auto Dropped Chests & Loot",
	description = "Opens nearby dropped chests and collects loot reserved for you",
	value = false,
	forgetState = true,
	callback = function(value)
		Automation.autoDroppedLootEnabled = value
		Automation.autoDroppedLootGeneration += 1

		if value then
			task.spawn(Automation.runAutoDroppedLootLoop, Automation.autoDroppedLootGeneration)
		end
	end,
})

Automation.automationTab:CreateButton({
	name = "Refresh Weapons",
	description = "Reloads owned weapons, unlocked skills and fishing bait",
	callback = function()
		local weapons = Automation.getOwnedWeaponOptions()
		local skills = Automation.getPowerSkillOptions(true)
		local bait = Automation.getFishingBaitOptions()

		Automation.weaponDropdown:Refresh(weapons)
		Automation.skillDropdown:Refresh(skills)
		Automation.baitDropdown:Refresh(bait)

		if selectedWeaponName and table.find(weapons, selectedWeaponName) then
			Automation.weaponDropdown:Set(selectedWeaponName, true)
		end

		if selectedFishingBait and table.find(bait, selectedFishingBait) then
			Automation.baitDropdown:Set(selectedFishingBait, true)
		end
	end,
})
Automation.automationTab:CreateButton({
	name = "Auto Equip Best Equipment",
	description = "Fills stat slots by numeric bonuses and vanity slots by rarity",
	callback = function()
		task.spawn(Automation.autoEquipBestEquipment)
	end,
})

Automation.automationTab:CreateButton({
	name = "Unlock Schematics",
	description = "Visits available study props and collects schematics you do not own",
	callback = function()
		task.spawn(Automation.unlockAllSchematics)
	end,
})
Automation.utilityTab:CreateDropdown({
	name = "Teleport Zone",
	options = Automation.getTeleportZoneOptions(),
	placeholder = "Select zone",
	forgetState = true,
	callback = function(value)
		Automation.selectedTeleportZone = value
	end,
})

Automation.utilityTab:CreateButton({
	name = "Teleport",
	description = "Moves the character to the selected runtime zone",
	callback = function()
		if Automation.selectedTeleportZone then
			Automation.teleportToZone(Automation.selectedTeleportZone)
		end
	end,
})

Automation.playerCombatTab:CreateToggle({
	name = "No Stun",
	description = "Keeps local walk speed and jump while stunned or rooted",
	value = false,
	forgetState = true,
	callback = function(value)
		noStunEnabled = value
	end,
})

Automation.playerCombatTab:CreateToggle({
	name = "Instant Kill",
	description = "Finishes network-owned NPCs below the selected health",
	value = false,
	forgetState = true,
	callback = function(value)
		Automation.instantKillEnabled = value
	end,
})

Automation.playerCombatTab:CreateSlider({
	name = "Damage Before Kill",
	description = "Health percentage before Instant Kill is used",
	range = {0, 100},
	increment = 1,
	value = Automation.instantKillThreshold,
	suffix = "%",
	forgetState = true,
	callback = function(value)
		Automation.instantKillThreshold = math.clamp(value, 0, 100)
	end,
})
Automation.playerCombatTab:CreateToggle({
	name = "No Ragdoll",
	description = "Uses the game's noragdoll client flag",
	value = false,
	forgetState = true,
	callback = function(value)
		noRagdollEnabled = value
		Automation.setNoRagdollEnabled(value)
	end,
})
Automation.playerCombatTab:CreateToggle({
	name = "No " .. "Attack Slowdown",
	description = "Removes the slow walk and jump after attacking",
	value = false,
	forgetState = true,
	callback = function(value)
		Automation.noAttackSlowdownEnabled = value
	end,
})

Automation.playerCombatTab:CreateToggle({
	name = "No Dash Cooldown",
	description = "Removes movement cooldowns while stamina rules stay active",
	value = false,
	forgetState = true,
	callback = function(value)
		Automation.noDashCooldownEnabled = value
	end,
})

Automation.playerCombatTab:CreateToggle({
	name = "Infinite Stamina",
	description = "Keeps local movement stamina full",
	value = false,
	forgetState = true,
	callback = function(value)
		Automation.infiniteStaminaEnabled = value
	end,
})

function Automation.setToggleState(toggle, value)
	if toggle and type(toggle.Set) == "function" then
		pcall(toggle.Set, toggle, value, true)
	end
end

Automation.UserInputService.InputBegan:Connect(function(input, processed)
	if processed or Automation.UserInputService:GetFocusedTextBox() then
		return
	end

	if input.KeyCode == Enum.KeyCode.H then
		Automation.flyEnabled = not Automation.flyEnabled
		Automation.setToggleState(Automation.flyToggle, Automation.flyEnabled)
		return
	end

	if input.KeyCode == Enum.KeyCode.N then
		Automation.manualNoclipEnabled = not Automation.manualNoclipEnabled
		Automation.setToggleState(Automation.noclipToggle, Automation.manualNoclipEnabled)
		return
	end

	if input.KeyCode == Enum.KeyCode.K then
		Automation.speedEnabled = not Automation.speedEnabled
		Automation.setToggleState(Automation.speedToggle, Automation.speedEnabled)
		return
	end

	if input.KeyCode == Enum.KeyCode.J then
		Automation.highJumpEnabled = not Automation.highJumpEnabled
		Automation.setToggleState(Automation.highJumpToggle, Automation.highJumpEnabled)
		return
	end

	if input.KeyCode == Enum.KeyCode.Space and Automation.noDashCooldownEnabled then
		local _, humanoid = getCharacter()
		if not humanoid or humanoid.FloorMaterial ~= Enum.Material.Air then
			return
		end

		local previousDashTime = Automation.DashHandler.LastDid

		task.delay(0.04, function()
			if not Automation.noDashCooldownEnabled then
				return
			end

			local _, currentHumanoid = getCharacter()
			if not currentHumanoid or currentHumanoid.FloorMaterial ~= Enum.Material.Air then
				return
			end

			if Automation.DashHandler.LastDid ~= previousDashTime then
				return
			end

			local success = SkillController.Attempt_Hold("Double Jump", "Space")
			if success == true then
				SkillController.StopHold("Double Jump")
				Automation.DashHandler.LastDid = tick()
			end
		end)
	end
end)

function Automation.stopOtherFarmModes(activeMode)
	if activeMode ~= "Quest" and farmEnabled then
		farmEnabled = false
		farmGeneration += 1
		Automation.setToggleState(questFarmToggle, false)
	end

	if activeMode ~= "Mob" and mobFarmEnabled then
		mobFarmEnabled = false
		mobFarmGeneration += 1
		Automation.setToggleState(mobFarmToggle, false)
	end

	if activeMode ~= "Chest" and autoChestEnabled then
		autoChestEnabled = false
		autoChestGeneration += 1
		Automation.setToggleState(autoChestToggle, false)
	end

	if activeMode ~= "Boss" and autoBossEnabled then
		autoBossEnabled = false
		autoBossGeneration += 1
		Automation.setToggleState(autoBossToggle, false)
	end

	if activeMode ~= "Breathing" and autoBreathingEnabled then
		autoBreathingEnabled = false
		autoBreathingGeneration += 1
		Automation.setToggleState(autoBreathingToggle, false)
	end

	if activeMode ~= "Dungeon" and Automation.autoDungeonEnabled then
		Automation.autoDungeonEnabled = false
		Automation.autoDungeonGeneration += 1
		Automation.setToggleState(Automation.dungeonToggle, false)
	end

	currentCombatTarget = nil
	setBlocking(false)
end
Automation.breathingOptions = Automation.getBreathingOptions()

if not selectedBreathingName and #Automation.breathingOptions > 0 then
	selectedBreathingName = Automation.breathingOptions[1]
end

Automation.breathingDropdown = Automation.automationTab:CreateDropdown({
	name = "Breathing",
	description = "Trainer style to learn",
	options = Automation.breathingOptions,
	value = selectedBreathingName,
	forgetState = true,
	callback = function(value)
		selectedBreathingName = value
		autoBreathingGeneration += 1

		if autoBreathingEnabled then
			task.spawn(Automation.runAutoBreathingLoop, autoBreathingGeneration)
		end
	end,
})

autoBreathingToggle = Automation.automationTab:CreateToggle({
	name = "Auto Breathing",
	description = "Takes the trainer quest, does the training and beats the trainee when the required cost is available",
	value = false,
	forgetState = true,
	callback = function(value)
		if value and not autoBreathingEnabled then
			Automation.stopOtherFarmModes("Breathing")
		end

		autoBreathingEnabled = value
		autoBreathingGeneration += 1

		if value then
			task.spawn(Automation.runAutoBreathingLoop, autoBreathingGeneration)
		else
			setBlocking(false)
		end
	end,
})

function Automation.copyQuestKeys(source)
	local copy = {}
	for _, questKey in ipairs(source) do
		table.insert(copy, questKey)
	end
	return copy
end

function Automation.refreshQuestDropdown(force)
	refreshQuestDefinitions()

	if force or not farmEnabled or #displayedQuestKeys == 0 then
		displayedQuestKeys = Automation.copyQuestKeys(getAvailableQuestKeys())
	end

	questDropdown:Refresh(displayedQuestKeys)

	if selectedQuestKey and table.find(displayedQuestKeys, selectedQuestKey) then
		questDropdown:Set(selectedQuestKey, true)
	end
end

refreshQuestDefinitions()
displayedQuestKeys = Automation.copyQuestKeys(getAvailableQuestKeys())

questDropdown = farmTab:CreateDropdown({
	name = "Quest",
	options = displayedQuestKeys,
	placeholder = "Select quest",
	forgetState = true,
	callback = function(value)
		if value == selectedQuestKey then
			return
		end

		farmGeneration += 1
		local generation = farmGeneration
		setBlocking(false)
		selectedQuestKey = value
		combatCombo = 1
		lastCombatAttack = 0
		nextCombatAttack = 0

		task.spawn(function()
			cancelOtherActiveQuests(value)

			if farmEnabled and farmGeneration == generation and selectedQuestKey == value then
				task.spawn(runFarmLoop, generation)
			end
		end)
	end,
})

questFarmToggle = farmTab:CreateToggle({
	name = "Farm",
	value = false,
	forgetState = true,
	callback = function(value)
		if value and not farmEnabled then
			Automation.stopOtherFarmModes("Quest")
			refreshQuestDefinitions()
			displayedQuestKeys = Automation.copyQuestKeys(getAvailableQuestKeys())
		end

		farmEnabled = value
		farmGeneration += 1
		combatCombo = 1
		lastCombatAttack = 0
		nextCombatAttack = 0

		if value then
			local generation = farmGeneration
			task.spawn(function()
				cancelOtherActiveQuests(selectedQuestKey)

				if farmEnabled and farmGeneration == generation then
					runFarmLoop(generation)
				end
			end)
		else
			setBlocking(false)
			task.defer(Automation.refreshQuestDropdown, true)
		end
	end,
})

farmTab:CreateDropdown({
	name = "Auto Attack",
	description = "Default uses weapon timing; Instant continuously spams attack requests",
	options = {"Default", "Instant"},
	value = Automation.autoAttackMode,
	forgetState = true,
	callback = function(value)
		Automation.autoAttackMode = value == "Instant" and "Instant" or "Default"
		nextCombatAttack = 0
	end,
})

farmTab:CreateDropdown({
	name = "Position Type",
	options = {"Above", "Below", "Behind", "Front"},
	value = farmPositionType,
	forgetState = true,
	callback = function(value)
		farmPositionType = value
	end,
})

farmTab:CreateSlider({
	name = "Offset Distance",
	range = {2, 10},
	increment = 0.5,
	value = farmOffsetDistance,
	suffix = " studs",
	forgetState = true,
	callback = function(value)
		farmOffsetDistance = math.clamp(value, 2, 10)
	end,
})

farmTab:CreateSlider({
	name = "Tween Speed",
	range = {40, 500},
	increment = 10,
	value = farmTweenSpeed,
	suffix = " studs/s",
	forgetState = true,
	callback = function(value)
		farmTweenSpeed = math.clamp(value, 40, 500)
	end,
})

farmTab:CreateToggle({
	name = "Auto Claim Souls",
	description = "Picks up souls within 25 studs of each kill before the farm moves on",
	value = false,
	forgetState = true,
	callback = function(value)
		autoClaimSoulsEnabled = value
	end,
})

farmTab:CreateToggle({
	name = "Auto Parry",
	description = "Perfect blocks incoming NPC swings and uses Anti Hit while parry is on cooldown",
	value = false,
	forgetState = true,
	callback = function(value)
		autoParryEnabled = value
		if not value then
			setBlocking(false)
		end
	end,
})

farmTab:CreateToggle({
	name = "Anti Hit",
	description = "Lifts you above a mob when parry is unavailable or disabled",
	value = false,
	forgetState = true,
	callback = function(value)
		antiHitEnabled = value
	end,
})
function Automation.refreshMobDropdown()
	local options = getMobFarmOptions()
	mobDropdown:Refresh(options)

	if selectedMobName and table.find(options, selectedMobName) then
		mobDropdown:Set(selectedMobName, true)
	end
end

mobDropdown = farmTab:CreateDropdown({
	name = "Mob",
	options = getMobFarmOptions(),
	placeholder = "Select mob or boss",
	forgetState = true,
	callback = function(value)
		selectedMobName = value
		mobFarmGeneration += 1
		combatCombo = 1
		lastCombatAttack = 0
		nextCombatAttack = 0
		setBlocking(false)

		if mobFarmEnabled then
			task.spawn(runMobFarmLoop, mobFarmGeneration)
		end
	end,
})

mobFarmToggle = farmTab:CreateToggle({
	name = "Auto Farm Mob",
	description = "Farms the selected mob or boss",
	value = false,
	forgetState = true,
	callback = function(value)
		if value and not mobFarmEnabled then
			Automation.stopOtherFarmModes("Mob")
		end

		mobFarmEnabled = value
		mobFarmGeneration += 1
		combatCombo = 1
		lastCombatAttack = 0
		nextCombatAttack = 0
		setBlocking(false)

		if value then
			task.spawn(runMobFarmLoop, mobFarmGeneration)
		end
	end,
})

function Automation.refreshBossDropdown()
	local options = getBossOptions()
	bossDropdown:Refresh(options)

	if selectedBossName and table.find(options, selectedBossName) then
		bossDropdown:Set(selectedBossName, true)
	end
end

autoChestToggle = farmTab:CreateToggle({
	name = "Auto Chest",
	description = "Kills sealed cache guards and opens the caches, can not run with other farms",
	value = false,
	forgetState = true,
	callback = function(value)
		if value and not autoChestEnabled then
			Automation.stopOtherFarmModes("Chest")
		end

		autoChestEnabled = value
		autoChestGeneration += 1
		combatCombo = 1
		lastCombatAttack = 0
		nextCombatAttack = 0
		setBlocking(false)

		if value then
			task.spawn(runAutoChestLoop, autoChestGeneration)
		end
	end,
})

bossDropdown = farmTab:CreateDropdown({
	name = "Boss",
	options = getBossOptions(),
	placeholder = "Select boss",
	forgetState = true,
	callback = function(value)
		selectedBossName = value
		autoBossGeneration += 1
		combatCombo = 1
		lastCombatAttack = 0
		nextCombatAttack = 0
		setBlocking(false)

		if autoBossEnabled then
			task.spawn(runAutoBossLoop, autoBossGeneration)
		end
	end,
})

autoBossToggle = farmTab:CreateToggle({
	name = "Auto Boss",
	description = "Farms the selected bosses as they respawn and opens their chests",
	value = false,
	forgetState = true,
	callback = function(value)
		if value and not autoBossEnabled then
			Automation.stopOtherFarmModes("Boss")
		end

		autoBossEnabled = value
		autoBossGeneration += 1
		combatCombo = 1
		lastCombatAttack = 0
		nextCombatAttack = 0
		setBlocking(false)

		if value then
			task.spawn(runAutoBossLoop, autoBossGeneration)
		end
	end,
})
function Automation.destroySafeHealthSlider()
	if safeHealthSlider and type(safeHealthSlider.Destroy) == "function" then
		local success = pcall(safeHealthSlider.Destroy, safeHealthSlider)
		if success then
			safeHealthSlider = nil
			return
		end
	end

	pcall(function()
		local tabPage = farmTab.tabPage
		if typeof(tabPage) == "Instance" then
			for _, descendant in ipairs(tabPage:GetDescendants()) do
				if descendant:IsA("TextLabel") and descendant.Text == "Safe HP" then
					local element = descendant
					while element.Parent and element.Parent ~= tabPage do
						element = element.Parent
					end
					if element.Parent == tabPage then
						element:Destroy()
						break
					end
				end
			end
		end
	end)

	safeHealthSlider = nil
end

function Automation.createSafeHealthSlider(maxHealth)
	maxHealth = math.max(1, math.floor(maxHealth + 0.5))

	if maxHealth == safeHealthMaximum and safeHealthSlider then
		return
	end

	safeHealthMaximum = maxHealth

	if safeHealthThresholdCustomized then
		safeHealthThreshold = math.clamp(safeHealthThreshold, 1, safeHealthMaximum)
	else
		safeHealthThreshold = math.clamp(math.floor(safeHealthMaximum * 0.3 + 0.5), 1, safeHealthMaximum)
	end

	Automation.destroySafeHealthSlider()

	safeHealthSliderCreating = true
	safeHealthSlider = farmTab:CreateSlider({
		name = "Safe HP",
		range = {1, safeHealthMaximum},
		increment = 1,
		value = safeHealthThreshold,
		suffix = " HP",
		forgetState = true,
		callback = function(value)
			if not safeHealthSliderCreating then
				safeHealthThresholdCustomized = true
			end
			safeHealthThreshold = math.clamp(math.floor(value + 0.5), 1, safeHealthMaximum)
		end,
	})
	safeHealthSliderCreating = false

	if safeHealthSlider and type(safeHealthSlider.MoveTo) == "function" then
		pcall(safeHealthSlider.MoveTo, safeHealthSlider, 3)
	end
end

function Automation.refreshSafeHealthSliderFromUi()
	local _, maximumHealth = getHudDisplayedHealth()
	if maximumHealth then
		Automation.createSafeHealthSlider(maximumHealth)
	end
end

function Automation.createSafeDebugElement()
	local attempts = {
		function()
			return farmTab:CreateStat({
				name = "Safe Debug",
				value = "Waiting for HUD",
			}), "Stat"
		end,
		function()
			return farmTab:CreateLabel("Safe Debug | Waiting for HUD"), "Label"
		end,
		function()
			return farmTab:CreateParagraph({
				title = "Safe Debug",
				content = "Waiting for HUD",
			}), "Paragraph"
		end,
	}

	for _, attempt in ipairs(attempts) do
		local success, handle, kind = pcall(attempt)
		if success and handle then
			return handle, kind
		end
	end

	return nil, nil
end

local safeDebugKind
safeDebugStat = nil

function Automation.updateSafeDebug()
	if not safeDebugStat or type(safeDebugStat.Set) ~= "function" then
		return
	end

	local hudCurrent, hudMaximum = getHudDisplayedHealth()
	local currentHealth, maximumHealth, label = getDisplayedHealth()
	local sourceName = label and "HUD" or "Fallback"
	local stateName = safeRetreatActive and "Retreat" or "Idle"
	local hudText = hudCurrent and hudMaximum and ("%s/%s"):format(
		tostring(math.floor(hudCurrent + 0.5)),
		tostring(math.floor(hudMaximum + 0.5))
	) or "Missing"
	local value = ("HUD %s | Active %s %s/%s | SliderMax %s | Threshold %s | %s"):format(
		hudText,
		sourceName,
		currentHealth and tostring(math.floor(currentHealth + 0.5)) or "?",
		maximumHealth and tostring(math.floor(maximumHealth + 0.5)) or "?",
		tostring(safeHealthMaximum),
		tostring(safeHealthThreshold),
		stateName
	)

	if safeDebugKind == "Stat" then
		pcall(safeDebugStat.Set, safeDebugStat, {value = value})
	elseif safeDebugKind == "Paragraph" then
		pcall(safeDebugStat.Set, safeDebugStat, {title = "Safe Debug", content = value})
	else
		pcall(safeDebugStat.Set, safeDebugStat, "Safe Debug | " .. value)
	end
end

farmTab:CreateToggle({
	name = "Auto Safe",
	value = false,
	forgetState = true,
	callback = function(value)
		autoSafeEnabled = value
		autoSafeGeneration += 1

		if value then
			task.spawn(runAutoSafeLoop, autoSafeGeneration)
		else
			setBlocking(false)
			if safeReturnCFrame then
				returnFromSafeRetreat()
			else
				safeRetreatActive = false
			end
		end
	end,
})

task.spawn(function()
	while true do
		Automation.refreshSafeHealthSliderFromUi()
		task.wait(0.25)
	end
end)

task.spawn(function()
	while true do
		Automation.refreshQuestDropdown(false)
		Automation.refreshMobDropdown()
		Automation.refreshBossDropdown()

		if Automation.skillNodeDropdown then
			Automation.skillNodeDropdown:Refresh(Automation.getSkillTreeNodeOptions())
		end

		if Automation.weaponDropdown then
			Automation.weaponDropdown:Refresh(Automation.getOwnedWeaponOptions())
			if selectedWeaponName and table.find(Automation.getOwnedWeaponOptions(), selectedWeaponName) then
				Automation.weaponDropdown:Set(selectedWeaponName, true)
			end
		end

		if Automation.skillDropdown then
			Automation.skillDropdown:Refresh(Automation.getPowerSkillOptions(true))
		end

		if Automation.potionDropdown then
			local potionOptions = Automation.getPotionOptions()
			Automation.potionDropdown:Refresh(potionOptions)
			if selectedPotionName and table.find(potionOptions, selectedPotionName) then
				Automation.potionDropdown:Set(selectedPotionName, true)
			end
		end

		if Automation.baitDropdown then
			local baitOptions = Automation.getFishingBaitOptions()
			Automation.baitDropdown:Refresh(baitOptions)
			if selectedFishingBait and table.find(baitOptions, selectedFishingBait) then
				Automation.baitDropdown:Set(selectedFishingBait, true)
			end
		end

		if Automation.recipeDropdown then
			Automation.recipeDropdown:Refresh(Automation.getCraftRecipeOptions())
		end

		if Automation.breathingDropdown and not autoBreathingEnabled then
			Automation.breathingOptions = Automation.getBreathingOptions()
			Automation.breathingDropdown:Refresh(Automation.breathingOptions)
			if selectedBreathingName and table.find(Automation.breathingOptions, selectedBreathingName) then
				Automation.breathingDropdown:Set(selectedBreathingName, true)
			end
		end

		task.wait(3)
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	combatCombo = 1
	lastCombatAttack = 0
	nextCombatAttack = 0
	blockingEnabled = false
	lastAutoParry = -math.huge
	safeRetreatActive = false
	safeReturnCFrame = nil
	safeRetreatDirection = nil
	currentCombatTarget = nil
end)
