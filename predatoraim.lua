-- =====================================================================
-- PREDATOR LITE : ENGINE + CLEAN GUI (FINAL OPTIMIZED v2)
-- Restored: Smoothness slider (Scale 1-100) for high-speed Lerp locking.
-- =====================================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ==========================================
-- [0] MOUNTING & CLEANUP
-- ==========================================
local function GetGUIParent()
    local s, r = pcall(function() return gethui() end)
    if s and r then return r end
    local s2, r2 = pcall(function() return game:GetService("CoreGui") end)
    if s2 and r2 then return r2 end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local GuiParent = GetGUIParent()

if getgenv().PREDATOR_Cleanup then
    pcall(getgenv().PREDATOR_Cleanup)
end
pcall(function()
    local old = GuiParent:FindFirstChild("PredatorLite_UI")
    if old then old:Destroy() end
end)

-- ==========================================
-- [1] CONFIGURATION
-- ==========================================
getgenv().CFG = {
    AimbotEnabled = false,
    ChamsEnabled  = true,
    WallCheck     = true,
    TeamCheck     = true,
    ShowFOV       = true,
    FOV           = 150,
    Smoothness    = 50, -- Slider dikembalikan
    TargetBone    = "Head",
}

local TargetLocked = nil
local ChamsCache   = {}
local Connections  = {}

-- ==========================================
-- [2] CLEAN UI BUILDER
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PredatorLite_UI"
ScreenGui.Parent = GuiParent
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.ResetOnSpawn = false

local FOVFrame = Instance.new("Frame")
FOVFrame.Parent = ScreenGui
FOVFrame.BackgroundTransparency = 1
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVFrame.Size = UDim2.new(0, getgenv().CFG.FOV * 2, 0, getgenv().CFG.FOV * 2)
FOVFrame.Visible = false
local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVFrame
local FOVStroke = Instance.new("UIStroke")
FOVStroke.Parent = FOVFrame
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Thickness = 1.5
FOVStroke.Transparency = 0.2

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -175)
MainFrame.Size = UDim2.new(0, 260, 0, 360)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 6)
MainCorner.Parent = MainFrame
local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Color = Color3.fromRGB(40, 40, 40)
MainStroke.Thickness = 1

local TopBar = Instance.new("Frame")
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BorderSizePixel = 0

local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "PREDATOR LITE"
Title.TextColor3 = Color3.fromRGB(200, 50, 50)
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton")
MinBtn.Parent = TopBar
MinBtn.BackgroundTransparency = 1
MinBtn.Position = UDim2.new(1, -35, 0, 0)
MinBtn.Size = UDim2.new(0, 35, 1, 0)
MinBtn.Font = Enum.Font.Gotham
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
MinBtn.TextSize = 16

local Content = Instance.new("Frame")
Content.Parent = MainFrame
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0, 0, 0, 35)
Content.Size = UDim2.new(1, 0, 1, -35)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Content
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 2)

local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = minimized and UDim2.new(0, 260, 0, 35) or UDim2.new(0, 260, 0, 360)}):Play()
    MinBtn.Text = minimized and "+" or "-"
end)

local function CreateToggle(text, cfgKey)
    local Frame = Instance.new("Frame")
    Frame.Parent = Content; Frame.BackgroundTransparency = 1; Frame.Size = UDim2.new(1, 0, 0, 35)
    
    local Label = Instance.new("TextLabel")
    Label.Parent = Frame; Label.BackgroundTransparency = 1; Label.Position = UDim2.new(0, 15, 0, 0); Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Font = Enum.Font.Gotham; Label.Text = text; Label.TextColor3 = Color3.fromRGB(220, 220, 220); Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left

    local ToggleBG = Instance.new("TextButton")
    ToggleBG.Parent = Frame; ToggleBG.BackgroundColor3 = getgenv().CFG[cfgKey] and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(40, 40, 40)
    ToggleBG.Position = UDim2.new(1, -50, 0.5, -10); ToggleBG.Size = UDim2.new(0, 36, 0, 20); ToggleBG.Text = ""; ToggleBG.AutoButtonColor = false
    Instance.new("UICorner", ToggleBG).CornerRadius = UDim.new(1, 0)

    local Circle = Instance.new("Frame")
    Circle.Parent = ToggleBG; Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.Position = getgenv().CFG[cfgKey] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8); Circle.Size = UDim2.new(0, 16, 0, 16)
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

    ToggleBG.MouseButton1Click:Connect(function()
        getgenv().CFG[cfgKey] = not getgenv().CFG[cfgKey]
        local state = getgenv().CFG[cfgKey]
        TweenService:Create(ToggleBG, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(40, 40, 40)}):Play()
        TweenService:Create(Circle, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
    end)
end

local function CreateSlider(text, min, max, cfgKey)
    local Frame = Instance.new("Frame")
    Frame.Parent = Content; Frame.BackgroundTransparency = 1; Frame.Size = UDim2.new(1, 0, 0, 45)

    local Label = Instance.new("TextLabel")
    Label.Parent = Frame; Label.BackgroundTransparency = 1; Label.Position = UDim2.new(0, 15, 0, 5); Label.Size = UDim2.new(0.5, 0, 0, 15)
    Label.Font = Enum.Font.Gotham; Label.Text = text; Label.TextColor3 = Color3.fromRGB(220, 220, 220); Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Parent = Frame; ValLabel.BackgroundTransparency = 1; ValLabel.Position = UDim2.new(1, -65, 0, 5); ValLabel.Size = UDim2.new(0, 50, 0, 15)
    ValLabel.Font = Enum.Font.GothamBold; ValLabel.Text = tostring(getgenv().CFG[cfgKey]); ValLabel.TextColor3 = Color3.fromRGB(200, 50, 50); ValLabel.TextSize = 11; ValLabel.TextXAlignment = Enum.TextXAlignment.Right

    local SliderBG = Instance.new("TextButton")
    SliderBG.Parent = Frame; SliderBG.BackgroundColor3 = Color3.fromRGB(30, 30, 30); SliderBG.Position = UDim2.new(0, 15, 0, 25); SliderBG.Size = UDim2.new(1, -30, 0, 6); SliderBG.Text = ""; SliderBG.AutoButtonColor = false
    Instance.new("UICorner", SliderBG).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame")
    Fill.Parent = SliderBG; Fill.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    Fill.Size = UDim2.new((getgenv().CFG[cfgKey] - min) / (max - min), 0, 1, 0)
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    
    local Knob = Instance.new("Frame")
    Knob.Parent = Fill; Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.Position = UDim2.new(1, -5, 0.5, -5); Knob.Size = UDim2.new(0, 10, 0, 10)
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local draggingSlider = false
    local function Update(input)
        local percent = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + ((max - min) * percent))
        getgenv().CFG[cfgKey] = val
        ValLabel.Text = tostring(val)
        TweenService:Create(Fill, TweenInfo.new(0.1), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
    end

    SliderBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = true; Update(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then Update(input) end
    end)
end

local function CreateDivider()
    local frame = Instance.new("Frame")
    frame.Parent = Content; frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30); frame.Size = UDim2.new(1, 0, 0, 1); frame.BorderSizePixel = 0
end

-- Populate GUI
CreateToggle("Enable Aimbot", "AimbotEnabled")
CreateToggle("Enable Chams", "ChamsEnabled")
CreateDivider()
CreateToggle("Wall Check", "WallCheck")
CreateToggle("Team Check", "TeamCheck")
CreateToggle("Show FOV", "ShowFOV")
CreateDivider()
CreateSlider("FOV Radius", 10, 400, "FOV")
CreateSlider("Aim Smoothness", 1, 100, "Smoothness") -- Max diatur ke 100

-- ==========================================
-- [3] ENGINE LOGIC
-- ==========================================
local ViewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
table.insert(Connections, Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    ViewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end))

local function IsVisible(targetPart)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    params.IgnoreWater = true
    local origin = Camera.CFrame.Position
    local res = Workspace:Raycast(origin, targetPart.Position - origin, params)
    return (res and res.Instance:IsDescendantOf(targetPart.Parent)) or (not res)
end

local function IsValidTarget(player)
    if player == LocalPlayer or not player.Character then return false end
    local hum = player.Character:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if getgenv().CFG.TeamCheck and LocalPlayer.Team == player.Team then return false end
    return true
end

local function GetTargetPart(char)
    return char:FindFirstChild(getgenv().CFG.TargetBone) or char:FindFirstChild("HumanoidRootPart")
end

local function GetClosestTarget()
    local closest, bestDist = nil, getgenv().CFG.FOV
    local camPos = Camera.CFrame.Position
    
    for _, p in ipairs(Players:GetPlayers()) do
        if IsValidTarget(p) then
            local part = GetTargetPart(p.Character)
            if part then
                if (part.Position - camPos).Magnitude > 1500 then continue end
                
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - ViewportCenter).Magnitude
                    if dist < bestDist then
                        if not getgenv().CFG.WallCheck or IsVisible(part) then
                            closest = p
                            bestDist = dist
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function CreateChams(player)
    if ChamsCache[player] or player == LocalPlayer then return end
    local hl = Instance.new("Highlight")
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0.2
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    pcall(function() hl.Parent = GuiParent end)
    ChamsCache[player] = hl
end

for _, p in ipairs(Players:GetPlayers()) do CreateChams(p) end
table.insert(Connections, Players.PlayerAdded:Connect(CreateChams))
table.insert(Connections, Players.PlayerRemoving:Connect(function(p)
    if ChamsCache[p] then ChamsCache[p]:Destroy(); ChamsCache[p] = nil end
end))

-- Asynchronous Chams Updater
task.spawn(function()
    while task.wait(0.5) do
        if not getgenv().PREDATOR_Cleanup then break end
        local cfg = getgenv().CFG
        for player, highlight in pairs(ChamsCache) do
            if cfg.ChamsEnabled and IsValidTarget(player) and player.Character then
                highlight.Adornee = player.Character
                highlight.Enabled = true
                if LocalPlayer.Team ~= player.Team then
                    highlight.FillColor = Color3.fromRGB(200, 50, 50)
                    highlight.OutlineColor = Color3.fromRGB(150, 0, 0)
                else
                    highlight.FillColor = Color3.fromRGB(50, 200, 50)
                    highlight.OutlineColor = Color3.fromRGB(0, 150, 0)
                end
            else
                highlight.Enabled = false
            end
        end
    end
end)

-- Render-Bound Aimbot Updater
table.insert(Connections, RunService.RenderStepped:Connect(function(deltaTime)
    local cfg = getgenv().CFG
    
    FOVFrame.Size = UDim2.new(0, cfg.FOV * 2, 0, cfg.FOV * 2)
    FOVFrame.Visible = cfg.ShowFOV
    FOVStroke.Color = TargetLocked and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(255, 255, 255)

    if cfg.AimbotEnabled then
        TargetLocked = GetClosestTarget()
        if TargetLocked then
            local part = GetTargetPart(TargetLocked.Character)
            if part then
                local targetCFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                local smoothSpeed = math.clamp(cfg.Smoothness * deltaTime, 0.01, 1)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothSpeed)
            end
        end
    else
        TargetLocked = nil
    end
end))

-- Global Cleanup
getgenv().PREDATOR_Cleanup = function()
    for _, conn in ipairs(Connections) do conn:Disconnect() end
    Connections = {}
    if ScreenGui then ScreenGui:Destroy() end
    for _, hl in pairs(ChamsCache) do if hl then hl:Destroy() end end
    ChamsCache = {}
    TargetLocked = nil
    getgenv().PREDATOR_Cleanup = nil
end
