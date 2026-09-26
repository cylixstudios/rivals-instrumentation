--[[
    Rivals Instrumentation Suite — Targeting Engine
    Vector Calculation, Entity Tracking, FOV Gate, Raycast Interception
    Target: Luau / Roblox Client
--]]

local Targeting = {}
Targeting.__index = Targeting

-- Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Helper to check if Drawing API exists
local hasDrawing = (type(Drawing) == "table" or type(Drawing) == "userdata" or type(Drawing) == "function")

function Targeting.new(config)
    config = config or {}

    local self = setmetatable({
        Enabled = config.Enabled or false,
        TeamCheck = config.TeamCheck ~= false, -- Default true
        WallCheck = config.WallCheck or false,
        Prediction = config.Prediction or false,
        PredictionFactor = config.PredictionFactor or 0.05,
        TargetPart = config.TargetPart or "Head", -- "Head", "HumanoidRootPart", "Torso", "Closest"
        AimMode = config.AimMode or "Camera", -- "Camera", "Mouse", "Silent"
        Smoothness = config.Smoothness or 0.2, -- 0 (instant) to 1 (slow)
        Priority = config.Priority or "Crosshair", -- "Crosshair", "Distance"

        -- FOV Circle
        ShowFOV = config.ShowFOV or true,
        FOVRadius = config.FOVRadius or 120,
        FOVColor = config.FOVColor or Color3.fromRGB(99, 102, 241),
        FOVCircle = nil,

        -- State
        CurrentTarget = nil,
        Aiming = false,
        ActivationKey = config.ActivationKey or Enum.UserInputType.MouseButton2,
        IsMouseButton = true,

        Connections = {},
        OriginalNamecall = nil
    }, Targeting)

    -- Initialize FOV Circle if Drawing API is present
    if hasDrawing then
        local circle = Drawing.new("Circle")
        circle.Visible = self.ShowFOV
        circle.Radius = self.FOVRadius
        circle.Color = self.FOVColor
        circle.Thickness = 1.5
        circle.Transparency = 0.85
        circle.Filled = false
        circle.NumSides = 64
        circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        self.FOVCircle = circle
    end

    self:Init()
    return self
end

-- Resolve Target Character in Rivals
function Targeting:ResolveCharacter(player)
    if not player then return nil end

    -- Primary: Standard character reference
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        return player.Character
    end

    -- Secondary: Rivals custom Characters folder in workspace
    local rivalsChars = Workspace:FindFirstChild("Characters") or Workspace:FindFirstChild("Entities")
    if rivalsChars then
        local found = rivalsChars:FindFirstChild(player.Name)
        if found and found:FindFirstChild("HumanoidRootPart") then
            return found
        end
    end

    -- Fallback: Search workspace for matching player name model
    local fallback = Workspace:FindFirstChild(player.Name)
    if fallback and fallback:IsA("Model") and fallback:FindFirstChild("HumanoidRootPart") then
        return fallback
    end

    return nil
end

-- Check Team Membership
function Targeting:IsTeammate(player)
    if not self.TeamCheck then return false end
    if not player or not LocalPlayer then return false end

    -- Check Roblox Team
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return true
    end

    -- Check Rivals Team Color or Attribute
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

-- Check Line of Sight (Wallcheck)
function Targeting:IsVisible(origin, targetPart, targetChar)
    local targetPos = targetPart.Position
    local direction = targetPos - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local excludeList = {Camera}
    local localChar = self:ResolveCharacter(LocalPlayer)
    if localChar then table.insert(excludeList, localChar) end

    params.FilterDescendantsInstances = excludeList
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, params)
    if not result then
        return true
    end

    if result.Instance and (result.Instance:IsDescendantOf(targetChar) or result.Instance == targetPart) then
        return true
    end

    return false
end

-- Get Specific Bone / Target Part
function Targeting:GetTargetBone(character)
    if not character then return nil end

    if self.TargetPart == "Closest" then
        local parts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
        local bestPart = nil
        local closestDist = math.huge
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

        for _, partName in ipairs(parts) do
            local p = character:FindFirstChild(partName)
            if p then
                local screenPos, onScreen = Camera:WorldToViewportPoint(p.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        bestPart = p
                    end
                end
            end
        end
        return bestPart or character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    end

    if self.TargetPart == "Torso" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    end

    return character:FindFirstChild(self.TargetPart) or character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

-- Target Selection Pipeline
function Targeting:GetBestTarget()
    local bestTarget = nil
    local bestPart = nil
    local bestScore = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local camPos = Camera.CFrame.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not self:IsTeammate(player) then
            local char = self:ResolveCharacter(player)
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local rootPart = char:FindFirstChild("HumanoidRootPart")
                local isAlive = humanoid and humanoid.Health > 0

                -- Check ForceField (invulnerability)
                local hasForceField = char:FindFirstChildOfClass("ForceField") ~= nil

                if isAlive and rootPart and not hasForceField then
                    local targetBone = self:GetTargetBone(char)
                    if targetBone then
                        local worldPos = targetBone.Position

                        -- Velocity Prediction
                        if self.Prediction and rootPart.AssemblyLinearVelocity then
                            worldPos = worldPos + (rootPart.AssemblyLinearVelocity * self.PredictionFactor)
                        end

                        local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
                        if onScreen and screenPos.Z > 0 then
                            local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

                            if screenDist <= self.FOVRadius then
                                local isPassWallcheck = true
                                if self.WallCheck then
                                    isPassWallcheck = self:IsVisible(camPos, targetBone, char)
                                end

                                if isPassWallcheck then
                                    local score
                                    if self.Priority == "Crosshair" then
                                        score = screenDist
                                    else
                                        score = (camPos - worldPos).Magnitude
                                    end

                                    if score < bestScore then
                                        bestScore = score
                                        bestTarget = player
                                        bestPart = targetBone
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return bestTarget, bestPart
end

-- Align Aim to Target
function Targeting:AlignTo(targetPart)
    if not targetPart then return end

    local targetPos = targetPart.Position
    local char = targetPart.Parent
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")

    if self.Prediction and rootPart and rootPart.AssemblyLinearVelocity then
        targetPos = targetPos + (rootPart.AssemblyLinearVelocity * self.PredictionFactor)
    end

    if self.AimMode == "Camera" then
        local camPos = Camera.CFrame.Position
        local targetCFrame = CFrame.new(camPos, targetPos)
        local smoothFactor = math.clamp(1 - self.Smoothness, 0.05, 1)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothFactor)
    elseif self.AimMode == "Mouse" and mousemoverel then
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
        if onScreen then
            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local deltaX = screenPos.X - screenCenter.X
            local deltaY = screenPos.Y - screenCenter.Y
            local smoothFactor = math.clamp(1 - self.Smoothness, 0.1, 1)
            mousemoverel(deltaX * smoothFactor, deltaY * smoothFactor)
        end
    end
end

-- Initialize Listeners and Loops
function Targeting:Init()
    -- Input Listeners for Aim Activation
    local inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == self.ActivationKey or input.KeyCode == self.ActivationKey then
            self.Aiming = true
        end
    end)
    table.insert(self.Connections, inputBegan)

    local inputEnded = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == self.ActivationKey or input.KeyCode == self.ActivationKey then
            self.Aiming = false
            self.CurrentTarget = nil
        end
    end)
    table.insert(self.Connections, inputEnded)

    -- Frame Render Step Loop
    local renderConn = RunService.RenderStepped:Connect(function()
        -- Update FOV circle
        if self.FOVCircle then
            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            self.FOVCircle.Position = center
            self.FOVCircle.Radius = self.FOVRadius
            self.FOVCircle.Color = self.FOVColor
            self.FOVCircle.Visible = self.ShowFOV and self.Enabled
        end

        if not self.Enabled then return end

        if self.Aiming or self.AimMode == "Silent" then
            local targetPlayer, targetPart = self:GetBestTarget()
            self.CurrentTarget = targetPlayer

            if self.Aiming and targetPart and self.AimMode ~= "Silent" then
                self:AlignTo(targetPart)
            end
        else
            self.CurrentTarget = nil
        end
    end)
    table.insert(self.Connections, renderConn)

    -- Silent Metamethod Hook Setup
    self:SetupSilentMetamethod()
end

-- Metamethod Interception for Silent Targeting Mode
function Targeting:SetupSilentMetamethod()
    if not hookmetamethod then return end

    local rawMeta = getrawmetatable or debug.getmetatable
    if not rawMeta then return end

    local gMeta = rawMeta(game)
    if not gMeta then return end

    setreadonly(gMeta, false)
    local oldNamecall = gMeta.__namecall
    self.OriginalNamecall = oldNamecall

    local targetingSelf = self

    hookmetamethod(game, "__namecall", newcclosure(function(selfObj, ...)
        local method = getnamecallmethod()
        local args = {...}

        if targetingSelf.Enabled and targetingSelf.AimMode == "Silent" then
            if method == "Raycast" and selfObj == Workspace then
                local targetPlayer, targetPart = targetingSelf:GetBestTarget()
                if targetPart then
                    local origin = args[1]
                    local targetPos = targetPart.Position
                    local char = targetPart.Parent
                    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                    if targetingSelf.Prediction and rootPart and rootPart.AssemblyLinearVelocity then
                        targetPos = targetPos + (rootPart.AssemblyLinearVelocity * targetingSelf.PredictionFactor)
                    end
                    local newDirection = (targetPos - origin).Unit * 1000
                    args[2] = newDirection
                    return oldNamecall(selfObj, table.unpack(args))
                end
            elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                local targetPlayer, targetPart = targetingSelf:GetBestTarget()
                if targetPart and args[1] then
                    local ray = args[1]
                    local origin = ray.Origin
                    local targetPos = targetPart.Position
                    local newRay = Ray.new(origin, (targetPos - origin).Unit * 1000)
                    args[1] = newRay
                    return oldNamecall(selfObj, table.unpack(args))
                end
            end
        end

        return oldNamecall(selfObj, ...)
    end))
end

-- Destruction and Clean Unload
function Targeting:Destroy()
    for _, conn in ipairs(self.Connections) do
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end
    self.Connections = {}

    if self.FOVCircle then
        pcall(function()
            self.FOVCircle.Visible = false
            self.FOVCircle:Remove()
        end)
        self.FOVCircle = nil
    end

    if self.OriginalNamecall and hookmetamethod then
        pcall(function()
            hookmetamethod(game, "__namecall", self.OriginalNamecall)
        end)
    end
end

return Targeting
