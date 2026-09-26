--[[
    Rivals Instrumentation Suite — Visual Overlay Engine
    2D Bounding Box, Healthbar, Dynamic Skeletons, Tracers, Distance Labels, Engine Chams
    Target: Luau / Roblox Client
--]]

local Visuals = {}
Visuals.__index = Visuals

-- Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local hasDrawing = (type(Drawing) == "table" or type(Drawing) == "userdata" or type(Drawing) == "function")

function Visuals.new(config)
    config = config or {}

    local self = setmetatable({
        Enabled = config.Enabled or false,
        Boxes = config.Boxes or true,
        HealthBar = config.HealthBar or true,
        Names = config.Names or true,
        Distance = config.Distance or true,
        Weapon = config.Weapon or false,
        Tracers = config.Tracers or false,
        TracerOrigin = config.TracerOrigin or "Bottom", -- "Bottom", "Center", "Mouse"
        Skeletons = config.Skeletons or false,
        Chams = config.Chams or false,
        TeamCheck = config.TeamCheck ~= false,

        -- Styling
        BoxColor = config.BoxColor or Color3.fromRGB(99, 102, 241),
        TracerColor = config.TracerColor or Color3.fromRGB(129, 140, 248),
        SkeletonColor = config.SkeletonColor or Color3.fromRGB(248, 250, 252),
        ChamsFillColor = config.ChamsFillColor or Color3.fromRGB(99, 102, 241),
        ChamsOutlineColor = config.ChamsOutlineColor or Color3.fromRGB(255, 255, 255),
        ChamsFillTransparency = 0.5,
        ChamsOutlineTransparency = 0,

        EntityCache = {},
        Connections = {}
    }, Visuals)

    self:Init()
    return self
end

-- Resolve Target Character in Rivals
function Visuals:ResolveCharacter(player)
    if not player then return nil end

    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        return player.Character
    end

    local rivalsChars = Workspace:FindFirstChild("Characters") or Workspace:FindFirstChild("Entities")
    if rivalsChars then
        local found = rivalsChars:FindFirstChild(player.Name)
        if found and found:FindFirstChild("HumanoidRootPart") then
            return found
        end
    end

    local fallback = Workspace:FindFirstChild(player.Name)
    if fallback and fallback:IsA("Model") and fallback:FindFirstChild("HumanoidRootPart") then
        return fallback
    end

    return nil
end

-- Team Check Logic
function Visuals:IsTeammate(player)
    if not self.TeamCheck then return false end
    if not player or not LocalPlayer then return false end

    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return true
    end

    local char = self:ResolveCharacter(player)
    local localChar = self:ResolveCharacter(LocalPlayer)
    if char and localChar then
        local playerTeamAttr = char:GetAttribute("Team") or char:GetAttribute("TeamColor")
        local localTeamAttr = localChar:GetAttribute("Team") or localChar:GetAttribute("TeamColor")
        if playerTeamAttr and localTeamAttr and playerTeamAttr == localTeamAttr then
            return true
        end
    end

    return false
end

-- Construct Visual Container for an Entity
function Visuals:CreateEntityContainer(player)
    local container = {
        Player = player,
        BoxOutline = nil,
        Box = nil,
        HealthBarOutline = nil,
        HealthBar = nil,
        NameTag = nil,
        DistanceTag = nil,
        WeaponTag = nil,
        TracerLine = nil,
        SkeletonLines = {},
        ChamHighlight = nil
    }

    if hasDrawing then
        -- 2D Box Outline
        local boxOutline = Drawing.new("Square")
        boxOutline.Thickness = 3
        boxOutline.Filled = false
        boxOutline.Color = Color3.fromRGB(0, 0, 0)
        boxOutline.Transparency = 0.8
        boxOutline.Visible = false
        container.BoxOutline = boxOutline

        -- 2D Box Inner
        local box = Drawing.new("Square")
        box.Thickness = 1
        box.Filled = false
        box.Color = self.BoxColor
        box.Transparency = 1
        box.Visible = false
        container.Box = box

        -- Healthbar Outline
        local hbOutline = Drawing.new("Square")
        hbOutline.Thickness = 1
        hbOutline.Filled = true
        hbOutline.Color = Color3.fromRGB(0, 0, 0)
        hbOutline.Transparency = 0.7
        hbOutline.Visible = false
        container.HealthBarOutline = hbOutline

        -- Healthbar Fill
        local hb = Drawing.new("Square")
        hb.Thickness = 1
        hb.Filled = true
        hb.Color = Color3.fromRGB(34, 197, 94)
        hb.Transparency = 1
        hb.Visible = false
        container.HealthBar = hb

        -- Name Label
        local nameTag = Drawing.new("Text")
        nameTag.Text = player.DisplayName or player.Name
        nameTag.Size = 13
        nameTag.Center = true
        nameTag.Outline = true
        nameTag.OutlineColor = Color3.fromRGB(0, 0, 0)
        nameTag.Color = Color3.fromRGB(248, 250, 252)
        nameTag.Visible = false
        container.NameTag = nameTag

        -- Distance Label
        local distTag = Drawing.new("Text")
        distTag.Text = ""
        distTag.Size = 11
        distTag.Center = true
        distTag.Outline = true
        distTag.OutlineColor = Color3.fromRGB(0, 0, 0)
        distTag.Color = Color3.fromRGB(148, 163, 184)
        distTag.Visible = false
        container.DistanceTag = distTag

        -- Weapon Label
        local weaponTag = Drawing.new("Text")
        weaponTag.Text = ""
        weaponTag.Size = 11
        weaponTag.Center = true
        weaponTag.Outline = true
        weaponTag.OutlineColor = Color3.fromRGB(0, 0, 0)
        weaponTag.Color = Color3.fromRGB(234, 179, 8)
        weaponTag.Visible = false
        container.WeaponTag = weaponTag

        -- Tracer Line
        local tracer = Drawing.new("Line")
        tracer.Thickness = 1.5
        tracer.Color = self.TracerColor
        tracer.Transparency = 0.85
        tracer.Visible = false
        container.TracerLine = tracer

        -- Skeleton Lines (14 bone segments)
        for i = 1, 14 do
            local boneLine = Drawing.new("Line")
            boneLine.Thickness = 1.2
            boneLine.Color = self.SkeletonColor
            boneLine.Transparency = 0.8
            boneLine.Visible = false
            table.insert(container.SkeletonLines, boneLine)
        end
    end

    self.EntityCache[player] = container
    return container
end

-- Safely Hide Container
function Visuals:HideContainer(container)
    if not container then return end
    if container.BoxOutline then container.BoxOutline.Visible = false end
    if container.Box then container.Box.Visible = false end
    if container.HealthBarOutline then container.HealthBarOutline.Visible = false end
    if container.HealthBar then container.HealthBar.Visible = false end
    if container.NameTag then container.NameTag.Visible = false end
    if container.DistanceTag then container.DistanceTag.Visible = false end
    if container.WeaponTag then container.WeaponTag.Visible = false end
    if container.TracerLine then container.TracerLine.Visible = false end

    for _, boneLine in ipairs(container.SkeletonLines or {}) do
        boneLine.Visible = false
    end

    if container.ChamHighlight then
        container.ChamHighlight.Enabled = false
    end
end

-- Safely Destroy Container
function Visuals:DestroyContainer(player)
    local container = self.EntityCache[player]
    if not container then return end

    local function removeObj(obj)
        if obj then
            pcall(function()
                obj.Visible = false
                obj:Remove()
            end)
        end
    end

    removeObj(container.BoxOutline)
    removeObj(container.Box)
    removeObj(container.HealthBarOutline)
    removeObj(container.HealthBar)
    removeObj(container.NameTag)
    removeObj(container.DistanceTag)
    removeObj(container.WeaponTag)
    removeObj(container.TracerLine)

    for _, boneLine in ipairs(container.SkeletonLines or {}) do
        removeObj(boneLine)
    end

    if container.ChamHighlight then
        pcall(function() container.ChamHighlight:Destroy() end)
    end

    self.EntityCache[player] = nil
end

-- Skeleton Joint Connections
local R15Joints = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

local R6Joints = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

-- Render Entity Frame
function Visuals:RenderEntity(player, container)
    local char = self:ResolveCharacter(player)
    if not char then
        self:HideContainer(container)
        return
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart then
        self:HideContainer(container)
        return
    end

    if self:IsTeammate(player) then
        self:HideContainer(container)
        return
    end

    -- Highlights (Engine Chams)
    if self.Chams then
        if not container.ChamHighlight or container.ChamHighlight.Parent ~= char then
            pcall(function()
                if container.ChamHighlight then container.ChamHighlight:Destroy() end
                local hl = Instance.new("Highlight")
                hl.Name = "Instrumentation_Highlight"
                hl.Adornee = char
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillColor = self.ChamsFillColor
                hl.OutlineColor = self.ChamsOutlineColor
                hl.FillTransparency = self.ChamsFillTransparency
                hl.OutlineTransparency = self.ChamsOutlineTransparency
                hl.Parent = char
                container.ChamHighlight = hl
            end)
        end
        if container.ChamHighlight then
            container.ChamHighlight.Enabled = true
            container.ChamHighlight.FillColor = self.ChamsFillColor
            container.ChamHighlight.OutlineColor = self.ChamsOutlineColor
        end
    else
        if container.ChamHighlight then
            container.ChamHighlight.Enabled = false
        end
    end

    if not hasDrawing then return end

    -- Bounding Box Calculation
    local rootCFrame = rootPart.CFrame
    local rootPos = rootCFrame.Position
    local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos)

    if not onScreen or screenPos.Z <= 0 then
        self:HideContainer(container)
        return
    end

    -- Dynamic Height & Width based on perspective distance
    local head = char:FindFirstChild("Head")
    local headPos = head and head.Position or (rootPos + Vector3.new(0, 2, 0))
    local topWorld = headPos + Vector3.new(0, 0.8, 0)
    local bottomWorld = rootPos - Vector3.new(0, 3.0, 0)

    local topScreen, topOnScreen = Camera:WorldToViewportPoint(topWorld)
    local bottomScreen, bottomOnScreen = Camera:WorldToViewportPoint(bottomWorld)

    local boxHeight = math.abs(bottomScreen.Y - topScreen.Y)
    local boxWidth = math.max(boxHeight * 0.65, 6)
    local boxX = screenPos.X - (boxWidth / 2)
    local boxY = topScreen.Y

    -- Update 2D Box
    if self.Boxes then
        container.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
        container.BoxOutline.Position = Vector2.new(boxX, boxY)
        container.BoxOutline.Visible = true

        container.Box.Size = Vector2.new(boxWidth, boxHeight)
        container.Box.Position = Vector2.new(boxX, boxY)
        container.Box.Color = self.BoxColor
        container.Box.Visible = true
    else
        container.BoxOutline.Visible = false
        container.Box.Visible = false
    end

    -- Update Health Bar
    if self.HealthBar then
        local healthPct = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
        local barWidth = 3
        local barX = boxX - barWidth - 3
        local barHeight = boxHeight * healthPct

        container.HealthBarOutline.Size = Vector2.new(barWidth + 2, boxHeight + 2)
        container.HealthBarOutline.Position = Vector2.new(barX - 1, boxY - 1)
        container.HealthBarOutline.Visible = true

        container.HealthBar.Size = Vector2.new(barWidth, barHeight)
        container.HealthBar.Position = Vector2.new(barX, boxY + (boxHeight - barHeight))
        container.HealthBar.Color = Color3.fromHSV(healthPct * 0.33, 0.85, 0.95)
        container.HealthBar.Visible = true
    else
        container.HealthBarOutline.Visible = false
        container.HealthBar.Visible = false
    end

    -- Update Name Tag
    if self.Names then
        container.NameTag.Text = player.DisplayName or player.Name
        container.NameTag.Position = Vector2.new(boxX + (boxWidth / 2), boxY - 15)
        container.NameTag.Visible = true
    else
        container.NameTag.Visible = false
    end

    -- Update Distance Tag
    local distanceStuds = math.floor((Camera.CFrame.Position - rootPos).Magnitude)
    if self.Distance then
        container.DistanceTag.Text = string.format("[%d m]", math.floor(distanceStuds * 0.28))
        local bottomOffset = boxY + boxHeight + 2
        container.DistanceTag.Position = Vector2.new(boxX + (boxWidth / 2), bottomOffset)
        container.DistanceTag.Visible = true
    else
        container.DistanceTag.Visible = false
    end

    -- Update Weapon Tag
    if self.Weapon then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            container.WeaponTag.Text = tool.Name
            local distOffset = self.Distance and 14 or 2
            container.WeaponTag.Position = Vector2.new(boxX + (boxWidth / 2), boxY + boxHeight + distOffset)
            container.WeaponTag.Visible = true
        else
            container.WeaponTag.Visible = false
        end
    else
        container.WeaponTag.Visible = false
    end

    -- Update Tracer Line
    if self.Tracers then
        local originPos
        if self.TracerOrigin == "Bottom" then
            originPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        elseif self.TracerOrigin == "Mouse" then
            local mouseLoc = game:GetService("UserInputService"):GetMouseLocation()
            originPos = Vector2.new(mouseLoc.X, mouseLoc.Y)
        else -- Center
            originPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        end

        container.TracerLine.From = originPos
        container.TracerLine.To = Vector2.new(screenPos.X, boxY + boxHeight)
        container.TracerLine.Color = self.TracerColor
        container.TracerLine.Visible = true
    else
        container.TracerLine.Visible = false
    end

    -- Update Skeletons
    if self.Skeletons then
        local joints = (humanoid.RigType == Enum.HumanoidRigType.R15) and R15Joints or R6Joints
        for idx, boneLine in ipairs(container.SkeletonLines) do
            local jointPair = joints[idx]
            if jointPair then
                local partA = char:FindFirstChild(jointPair[1])
                local partB = char:FindFirstChild(jointPair[2])
                if partA and partB then
                    local posA, onScreenA = Camera:WorldToViewportPoint(partA.Position)
                    local posB, onScreenB = Camera:WorldToViewportPoint(partB.Position)

                    if onScreenA and onScreenB and posA.Z > 0 and posB.Z > 0 then
                        boneLine.From = Vector2.new(posA.X, posA.Y)
                        boneLine.To = Vector2.new(posB.X, posB.Y)
                        boneLine.Color = self.SkeletonColor
                        boneLine.Visible = true
                    else
                        boneLine.Visible = false
                    end
                else
                    boneLine.Visible = false
                end
            else
                boneLine.Visible = false
            end
        end
    else
        for _, boneLine in ipairs(container.SkeletonLines) do
            boneLine.Visible = false
        end
    end
end

-- Initialize Engine Listeners
function Visuals:Init()
    -- Initialize for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self:CreateEntityContainer(player)
        end
    end

    -- Player lifecycle listeners
    local playerAdded = Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            self:CreateEntityContainer(player)
        end
    end)
    table.insert(self.Connections, playerAdded)

    local playerRemoving = Players.PlayerRemoving:Connect(function(player)
        self:DestroyContainer(player)
    end)
    table.insert(self.Connections, playerRemoving)

    -- Main Render Step Loop
    local renderConn = RunService.RenderStepped:Connect(function()
        if not self.Enabled then
            for _, container in pairs(self.EntityCache) do
                self:HideContainer(container)
            end
            return
        end

        for player, container in pairs(self.EntityCache) do
            self:RenderEntity(player, container)
        end
    end)
    table.insert(self.Connections, renderConn)
end

-- Destruction and Full Teardown
function Visuals:Destroy()
    for _, conn in ipairs(self.Connections) do
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end
    self.Connections = {}

    for player in pairs(self.EntityCache) do
        self:DestroyContainer(player)
    end
    self.EntityCache = {}
end

return Visuals
