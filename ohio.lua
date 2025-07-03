local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local devv = require(game:GetService("ReplicatedStorage").devv)
local Signal = devv.load("Signal")

local lp = Players.LocalPlayer
local Plist = {}
local dateUpd = 0
local camera = workspace.CurrentCamera

local s = {
    aimbot = false,
    aimbotFOV = 100,
    aimbotPart = "Head",
    aimbotTeamCheck = true,
    aimbotVisibilityCheck = true,
    aimbotPrediction = 0.1,
    aimbotFOVCircle = true,
    aimbotTargetLock = false,
    aimbotSmoothing = false,
    aimbotSmoothness = 0,
    aimbotPriority = "Closest",
    j = false,
    m = false,
    v = 50,
    bhop = false,
    speedMultiplier = 1,
    wallCheckDistance = 5,
    moveDirectionControl = true
}

local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = true
Library.NotifySide = "Left"

local Window = Library:CreateWindow({
    Title = 'luaexploit.gg',
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    NotifySide = "Left",
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Combat = Window:AddTab('Combat'),
    Movement = Window:AddTab('Movement')
}

local AimbotBox = Tabs.Combat:AddLeftGroupbox('Aimbot')
AimbotBox:AddToggle('AimbotToggle', {Text = 'Enabled', Default = false, Callback = function(x) s.aimbot = x end})
AimbotBox:AddToggle('AimbotLock', {Text = 'Target Lock', Default = false, Callback = function(x) s.aimbotTargetLock = x end})
AimbotBox:AddDropdown('AimbotPart', {Text = 'Target Part', Default = 'Head', Values = {'Head', 'HumanoidRootPart', 'UpperTorso', 'LowerTorso'}, Callback = function(x) s.aimbotPart = x end})
AimbotBox:AddDropdown('AimbotPriority', {Text = 'Target Priority', Default = 'Closest', Values = {'Closest', 'FOV', 'Health', 'Distance'}, Callback = function(x) s.aimbotPriority = x end})
AimbotBox:AddSlider('AimbotFOV', {Text = 'FOV Size', Default = 100, Min = 1, Max = 1000, Rounding = 0, Callback = function(x) s.aimbotFOV = x end})
AimbotBox:AddSlider('AimbotPrediction', {Text = 'Prediction', Default = 0.1, Min = 0, Max = 1, Rounding = 2, Callback = function(x) s.aimbotPrediction = x end})
AimbotBox:AddToggle('SmoothingToggle', {Text = 'Smoothing', Default = false, Callback = function(x) s.aimbotSmoothing = x end})
AimbotBox:AddSlider('AimbotSmoothness', {Text = 'Smoothness', Default = 0, Min = 0, Max = 30, Rounding = 0, Callback = function(x) s.aimbotSmoothness = x end})
AimbotBox:AddToggle('FOVCircle', {Text = 'Show FOV Circle', Default = true, Callback = function(x) s.aimbotFOVCircle = x end})
AimbotBox:AddToggle('TeamCheck', {Text = 'Team Check', Default = true, Callback = function(x) s.aimbotTeamCheck = x end})
AimbotBox:AddToggle('VisibilityCheck', {Text = 'Visibility Check', Default = true, Callback = function(x) s.aimbotVisibilityCheck = x end})

local MovementBox = Tabs.Movement:AddLeftGroupbox('Movement')
MovementBox:AddToggle('HipJump', {Text = 'Hip Jump', Callback = function(x) s.j = x end})
MovementBox:AddSlider('WallCheckDistance', {Text = 'Wall Check Distance', Default = 5, Min = 1, Max = 20, Rounding = 0, Callback = function(x) s.wallCheckDistance = x end})
MovementBox:AddToggle('MoveBoost', {Text = 'Move Boost', Callback = function(x) s.m = x end})
MovementBox:AddToggle('DirectionControl', {Text = 'Direction Control', Default = true, Callback = function(x) s.moveDirectionControl = x end})
MovementBox:AddToggle('BunnyHop', {Text = 'Bunny Hop', Default = false, Callback = function(x) s.bhop = x end})
MovementBox:AddSlider('Speed', {Text = 'Move Speed', Default = 50, Min = 10, Max = 150, Rounding = 0, Callback = function(x) s.v = x end})
MovementBox:AddSlider('SpeedMultiplier', {Text = 'Speed Multiplier', Default = 1, Min = 1, Max = 5, Rounding = 1, Callback = function(x) s.speedMultiplier = x end})

local function UpdatePlist()
    local now = tick()
    if now - dateUpd < 0.5 then return end
    Plist = Players:GetPlayers()
    dateUpd = now
end

local function isEnemy(player)
    if not s.aimbotTeamCheck then return true end
    return player.Team ~= lp.Team or player.Team == nil or lp.Team == nil
end

local function isVisible(part)
    if not s.aimbotVisibilityCheck then return true end
    local origin = camera.CFrame.Position
    local direction = (part.Position - origin).Unit
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {lp.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local raycastResult = workspace:Raycast(origin, direction * 1000, raycastParams)
  return raycastResult and raycastResult.Instance:IsDescendantOf(part.Parent)
end

local function getPriorityValue(player, priority)
    local character = player.Character
    if not character then return math.huge end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return math.huge end
    local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return math.huge end
    local distance = (hrp.Position - myHrp.Position).Magnitude
    if priority == "Closest" then return distance
    elseif priority == "FOV" then
        local screenPoint = camera:WorldToViewportPoint(hrp.Position)
        local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        return (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
    elseif priority == "Health" then
        local humanoid = character:FindFirstChild("Humanoid")
        return humanoid and humanoid.Health or math.huge
    elseif priority == "Distance" then return distance end
    return math.huge
end

local function getBestTarget()
    UpdatePlist()
    local bestTarget, bestValue = nil, math.huge
    local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    for _, player in ipairs(Plist) do
        if player ~= lp and isEnemy(player) and player.Character then
            local targetPart = player.Character:FindFirstChild(s.aimbotPart)
            if targetPart and isVisible(targetPart) then
                local value = getPriorityValue(player, s.aimbotPriority)
                if value < bestValue then
                    bestValue = value
                    bestTarget = player
                end
            end
        end
    end
    return bestTarget
end

local function aimAtTarget(targetPart)
    if not targetPart then return end
    local targetPosition = targetPart.Position
    if s.aimbotPrediction > 0 and targetPart.Velocity.Magnitude > 0 then
        targetPosition = targetPosition + (targetPart.Velocity * s.aimbotPrediction)
    end
    if s.aimbotSmoothing and s.aimbotSmoothness > 0 then
        local currentLook = camera.CFrame.LookVector
        local desiredLook = (targetPosition - camera.CFrame.Position).Unit
        local smoothFactor = math.clamp(1 / (s.aimbotSmoothness + 1), 0.01, 1)
        camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + currentLook:Lerp(desiredLook, smoothFactor))
    else
        camera.CFrame = CFrame.new(camera.CFrame.Position, targetPosition)
    end
end

local function handleMovement()
    local c = lp.Character
    if not c then return end
    local h = c:FindFirstChild("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    if not h or not r then return end

    if s.j then
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {c}
        
        local baseRay = workspace:Raycast(r.Position, r.CFrame.LookVector * s.wallCheckDistance, params)
        
        if baseRay then
            local maxHeight = 100
            local step = 5
            local wallHeight = 0
            
            for height = step, maxHeight, step do
                local upperRay = workspace:Raycast(
                    r.Position + Vector3.new(0, height, 0),
                    r.CFrame.LookVector * s.wallCheckDistance,
                    params
                )
                
                if not upperRay then
                    wallHeight = height - step
                    break
                end
            end
            
            h.HipHeight = wallHeight + 5
        else
            h.HipHeight = 2
        end
    end

    if s.m and h.MoveDirection.Magnitude > 0 then
        local moveDir = h.MoveDirection.Unit
        if s.moveDirectionControl then
            local camCF = workspace.CurrentCamera.CFrame
            local right = camCF.RightVector * moveDir.X
            local forward = camCF.LookVector * moveDir.Z
            forward = Vector3.new(forward.X, 0, forward.Z).Unit
            moveDir = (right + forward).Unit
        end
        r.Velocity = moveDir * math.clamp(s.v / 2, 100, 750) * s.speedMultiplier + Vector3.new(0, r.Velocity.Y, 0)
    end

    if s.bhop and h.FloorMaterial ~= Enum.Material.Air then
        h.Jump = true
    end
end

RunService.Heartbeat:Connect(function()
    if s.aimbot then
        local target = getBestTarget()
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild(s.aimbotPart)
            if targetPart then aimAtTarget(targetPart) end
        end
    end
    handleMovement()
end)

Library:SetWatermarkVisibility(true)
Library:SetWatermark('luaexploit.gg')

local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1
    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end
    Library:SetWatermark(('luaexploit.gg | %s fps | %s ms'):format(math.floor(FPS), math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())))
end)

Library:OnUnload(function()
    Library.Unloaded = true
end)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SpinBot = {
    Enabled = false,
    Speed = 50,
    AntiDetection = true,
    RandomVariation = 5,
    VerticalSpin = false,
    _lastUpdate = 0
}

local function SafeUpdateSpinBot()
    if not SpinBot.Enabled then return end
    
    local character = Players.LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChildWhichIsA("BasePart")
    if not humanoidRootPart then return end
    
    local rotationSpeed = SpinBot.Speed or 0
    if SpinBot.AntiDetection then
        rotationSpeed = rotationSpeed + ((math.random() * 2 - 1) * (SpinBot.RandomVariation or 0))
    end
    
    rotationSpeed = math.clamp(rotationSpeed, -500, 500)
    
    local currentCFrame = humanoidRootPart.CFrame
    local rotationAxis = SpinBot.VerticalSpin and Vector3.new(0, 0, 1) or Vector3.new(0, 1, 0)
    local newCFrame = currentCFrame * CFrame.Angles(0, math.rad(rotationSpeed), 0)
    
    if SpinBot.AntiDetection then
        if math.random(1, 3) == 1 then
            humanoidRootPart.CFrame = newCFrame
        end
    else
        humanoidRootPart.CFrame = newCFrame
    end
end

RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - SpinBot._lastUpdate < (1/60) then return end
    SpinBot._lastUpdate = now
    SafeUpdateSpinBot()
end)

local CombatBox = Tabs.Combat:AddRightGroupbox('Spin Bot')
CombatBox:AddToggle('SpinBotEnabled', {
    Text = 'Enable Spin Bot',
    Default = SpinBot.Enabled,
    Callback = function(state)
        SpinBot.Enabled = state
    end
})

CombatBox:AddSlider('SpinBotSpeed', {
    Text = 'Spin Speed',
    Default = SpinBot.Speed,
    Min = 0,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        SpinBot.Speed = value
    end
})

CombatBox:AddToggle('SpinBotVertical', {
    Text = 'Vertical Spin',
    Default = SpinBot.VerticalSpin,
    Callback = function(state)
        SpinBot.VerticalSpin = state
    end
})

CombatBox:AddToggle('SpinBotAntiDetect', {
    Text = 'Anti-Detection',
    Default = SpinBot.AntiDetection,
    Callback = function(state)
        SpinBot.AntiDetection = state
    end
})
local BanInfo = {
    shadowbanned = nil,
    numshadowbans = 0,
    shadowbannedAt = 0,
    shadowbannedExpires = 0
}

-- Add Ban Info tab to the existing UI
local BanTab = Window:AddTab('Ban Info')

local BanBox = BanTab:AddLeftGroupbox('Ban Status')

-- Function to update ban information
local function UpdateBanInfo()
    for _, entry in ipairs(getgc(true)) do
        if type(entry) == "table" and rawget(entry, "shadowbannedExpires") then
            BanInfo.shadowbanned = rawget(entry, "shadowbanned")
            BanInfo.numshadowbans = rawget(entry, "numshadowbans") or 0
            BanInfo.shadowbannedAt = rawget(entry, "shadowbannedAt") or 0
            BanInfo.shadowbannedExpires = rawget(entry, "shadowbannedExpires") or 0
            break
        end
    end
end

-- Function to format timestamp
local function fmt(ts)
    return os.date("%Y-%m-%d %H:%M:%S", ts)
end

-- Function to calculate remaining time
local function GetRemainingTime(expires)
    local now = os.time()
    local rem = expires - now
    if rem > 0 then
        local d = math.floor(rem/86400); rem = rem%86400
        local h = math.floor(rem/3600);  rem = rem%3600
        local m = math.floor(rem/60);    rem = rem%60
        local s = rem
        return string.format("%d days %d hours %d minutes %d seconds", d, h, m, s)
    end
    return "No active ban"
end

-- Add UI elements
BanBox:AddLabel('Ban Status', true, 'BanStatusLabel')
BanBox:AddLabel('Ban Reason', true, 'BanReasonLabel')
BanBox:AddLabel('Ban Count', true, 'BanCountLabel')
BanBox:AddLabel('Banned At', true, 'BanTimeLabel')
BanBox:AddLabel('Expires At', true, 'ExpireTimeLabel')
BanBox:AddLabel('Time Remaining', true, 'RemainingLabel')

-- Refresh button
BanBox:AddButton({
    Text = 'Refresh Info',
    Func = function()
        UpdateBanInfo()
        Library:Notify("Ban information refreshed")
    end
})

-- Auto-update every 5 seconds
spawn(function()
    while wait(4) do
        if Library.Unloaded then break end
        UpdateBanInfo()
        
        -- Update UI labels
        Library.Labels.BanStatusLabel:SetText("Status: " .. (BanInfo.shadowbanned and "BANNED" or "CLEAN"))
        Library.Labels.BanReasonLabel:SetText("Reason: " .. (BanInfo.shadowbanned or "None"))
        Library.Labels.BanCountLabel:SetText("Total Bans: " .. BanInfo.numshadowbans)
        Library.Labels.BanTimeLabel:SetText("Banned At: " .. (BanInfo.shadowbannedAt > 0 and fmt(BanInfo.shadowbannedAt) or "Never"))
        Library.Labels.ExpireTimeLabel:SetText("Expires At: " .. (BanInfo.shadowbannedExpires > 0 and fmt(BanInfo.shadowbannedExpires) or "N/A"))
        Library.Labels.RemainingLabel:SetText("Time Left: " .. (BanInfo.shadowbannedExpires > 0 and GetRemainingTime(BanInfo.shadowbannedExpires) or "N/A"))
    end
end)

-- Initial update
UpdateBanInfo()
local Melee = {
    Active = false,
    SwingType = "meleejumpKick",
    HitCount = 8,
    Delay = 0.1,
    LastAttack = 0,
    MaxDistance = 50
}

local MeleeBox = Tabs.Combat:AddRightGroupbox('Auto Melee')
MeleeBox:AddToggle('AutoMeleeToggle', {
    Text = 'Auto Melee',
    Default = false,
    Callback = function(state)
        Melee.Active = state
    end
})

MeleeBox:AddSlider('MeleeHitCount', {
    Text = 'Hit Count',
    Default = 8,
    Min = 1,
    Max = 15,
    Rounding = 0,
    Callback = function(value)
        Melee.HitCount = value
    end
})

MeleeBox:AddSlider('MeleeDelay', {
    Text = 'Attack Delay',
    Default = 0.1,
    Min = 0.05,
    Max = 0.5,
    Rounding = 2,
    Callback = function(value)
        Melee.Delay = value
    end
})

local function UpdatePlayerList()
    local now = tick()
    if now - dateUpd < 0.5 then return end    
    Plist = Players:GetPlayers()
    dateUpd = now
end

local function GetClosestPlayer()
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local myPos = hrp.Position
    UpdatePlayerList()
    
    local closest, closestDist = nil, Melee.MaxDistance
    
    for _, player in ipairs(Plist) do
        if player ~= lp and player.Character then
            local hum = player.Character:FindFirstChild("Humanoid")
            local otherHRP = player.Character:FindFirstChild("HumanoidRootPart")
            
            if hum and hum.Health > 0 and otherHRP then
                local dist = (otherHRP.Position - myPos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = player
                end
            end
        end
    end
    
    return closest
end

local function ExecuteMelee(target)
    if not target then return end
    
    local now = tick()
    if now - Melee.LastAttack < Melee.Delay then return end
    Melee.LastAttack = now
    
    local hitArgs = {
        hitPlayerId = target.UserId,
        meleeType = Melee.SwingType
    }
    
    pcall(function()
        Signal.FireServer("meleeItemSwing", Melee.SwingType)
        for i = 1, Melee.HitCount do
            Signal.FireServer("meleeItemHit", "player", hitArgs)
        end
    end)
end

RunService.Heartbeat:Connect(function()
    if Melee.Active then
        local target = GetClosestPlayer()
        ExecuteMelee(target)
    end
end)
local ViewVisualizer = {
    Enabled = false,
    RefreshRate = 0.1,
    LastUpdate = 0,
    VisualParts = {},
    TargetPlayer = nil
}

local VisualBox = Tabs.Combat:AddLeftGroupbox('View Visualizer')

VisualBox:AddToggle('ViewVisualizerToggle', {
    Text = 'Enable View Visualizer',
    Default = false,
    Callback = function(state)
        ViewVisualizer.Enabled = state
        if not state then
            for _, part in pairs(ViewVisualizer.VisualParts) do
                part:Destroy()
            end
            ViewVisualizer.VisualParts = {}
        end
    end
})

VisualBox:AddDropdown('ViewTargetPlayer', {
    Text = 'Target Player',
    Default = 1,
    Values = {"None"},
    Callback = function(value)
        ViewVisualizer.TargetPlayer = value ~= "None" and game.Players[value] or nil
    end
})

local function UpdatePlayerList()
    local names = {"None"}
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp then
            table.insert(names, player.Name)
        end
    end
    Library.Options.ViewTargetPlayer.Values = names
    Library.Options.ViewTargetPlayer:SetValues()
end

UpdatePlayerList()
game.Players.PlayerAdded:Connect(UpdatePlayerList)
game.Players.PlayerRemoving:Connect(UpdatePlayerList)

local function CreateViewIndicator()
    local cone = Instance.new("Part")
    cone.Shape = Enum.PartType.Cylinder
    cone.Size = Vector3.new(5, 1, 1)
    cone.Transparency = 0.7
    cone.Color = Color3.fromRGB(0, 170, 255)
    cone.Anchored = true
    cone.CanCollide = false
    cone.CastShadow = false
    
    local line = Instance.new("Part")
    line.Size = Vector3.new(0.2, 0.2, 10)
    line.Transparency = 0.5
    line.Color = Color3.fromRGB(255, 255, 0)
    line.Anchored = true
    line.CanCollide = false
    line.CastShadow = false
    
    return {Cone = cone, Line = line}
end

local function UpdateViewVisualization()
    if not ViewVisualizer.Enabled or not ViewVisualizer.TargetPlayer then return end
    
    local targetChar = ViewVisualizer.TargetPlayer.Character
    if not targetChar then return end
    
    local head = targetChar:FindFirstChild("Head")
    if not head then return end
    
    if #ViewVisualizer.VisualParts == 0 then
        local parts = CreateViewIndicator()
        table.insert(ViewVisualizer.VisualParts, parts.Cone)
        table.insert(ViewVisualizer.VisualParts, parts.Line)
        parts.Cone.Parent = workspace
        parts.Line.Parent = workspace
    end
    
    local cameraCF = CFrame.new(head.Position, head.Position + (targetChar:GetRenderCFrame().LookVector * 10))
    
    ViewVisualizer.VisualParts[1].CFrame = cameraCF * CFrame.Angles(0, 0, math.rad(90))
    ViewVisualizer.VisualParts[2].CFrame = CFrame.new(head.Position, head.Position + (targetChar:GetRenderCFrame().LookVector * 10))
end

RunService.Heartbeat:Connect(function(deltaTime)
    if not ViewVisualizer.Enabled then return end
    
    local now = tick()
    if now - ViewVisualizer.LastUpdate < ViewVisualizer.RefreshRate then return end
    ViewVisualizer.LastUpdate = now
    
    pcall(UpdateViewVisualization)
end)
