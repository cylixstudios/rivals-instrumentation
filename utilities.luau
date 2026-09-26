--[[
    Rivals Instrumentation Suite — Entity Modifications & Client Physics Utilities
    Hitbox Expander, Character Physics, Infinite Jump, Noclip, Camera FOV, Fullbright
    Target: Luau / Roblox Client
--]]

local Utilities = {}
Utilities.__index = Utilities

-- Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

function Utilities.new()
    local self = setmetatable({
        -- Hitbox Expansion State
        HitboxExpanded = false,
        HitboxSize = 10,
        HitboxPart = "HumanoidRootPart", -- "HumanoidRootPart" or "Head"
        HitboxTransparency = 0.6,
        HitboxColor = Color3.fromRGB(99, 102, 241),
        OriginalHitboxes = {},

        -- Local Physics State
        SpeedEnabled = false,
        SpeedValue = 24,
        JumpEnabled = false,
        JumpValue = 60,
        InfiniteJump = false,
        Noclip = false,

        -- Camera & Lighting State
        CustomFOVEnabled = false,
        FOVValue = 90,
        Fullbright = false,
        OriginalLighting = {
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd
        },
        OriginalCameraFOV = Camera.FieldOfView,

        TeamCheck = true,
        Connections = {}
    }, Utilities)

    self:Init()
    return self
end

-- Resolve Target Character in Rivals
function Utilities:ResolveCharacter(player)
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
function Utilities:IsTeammate(player)
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

-- Apply Hitbox Expansion to Enemies
function Utilities:UpdateHitboxes()
    if not self.HitboxExpanded then
        self:RestoreHitboxes()
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not self:IsTeammate(player) then
            local char = self:ResolveCharacter(player)
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local targetPart = char:FindFirstChild(self.HitboxPart)

                if humanoid and humanoid.Health > 0 and targetPart then
                    if not self.OriginalHitboxes[targetPart] then
                        self.OriginalHitboxes[targetPart] = {
                            Size = targetPart.Size,
                            Transparency = targetPart.Transparency,
                            CanCollide = targetPart.CanCollide,
                            Material = targetPart.Material
                        }
                    end

                    targetPart.Size = Vector3.new(self.HitboxSize, self.HitboxSize, self.HitboxSize)
                    targetPart.Transparency = self.HitboxTransparency
                    targetPart.CanCollide = false
                end
            end
        end
    end
end

-- Restore Hitbox Sizes
function Utilities:RestoreHitboxes()
    for part, orig in pairs(self.OriginalHitboxes) do
        if part and part.Parent then
            pcall(function()
                part.Size = orig.Size
                part.Transparency = orig.Transparency
                part.CanCollide = orig.CanCollide
                part.Material = orig.Material
            end)
        end
    end
    self.OriginalHitboxes = {}
end

-- Apply Fullbright Environment
function Utilities:UpdateLighting()
    if self.Fullbright then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
    else
        Lighting.Ambient = self.OriginalLighting.Ambient
        Lighting.OutdoorAmbient = self.OriginalLighting.OutdoorAmbient
        Lighting.Brightness = self.OriginalLighting.Brightness
        Lighting.ClockTime = self.OriginalLighting.ClockTime
        Lighting.FogEnd = self.OriginalLighting.FogEnd
    end
end

-- Apply Camera Field of View
function Utilities:UpdateFOV()
    if self.CustomFOVEnabled then
        Camera.FieldOfView = self.FOVValue
    else
        Camera.FieldOfView = self.OriginalCameraFOV
    end
end

-- Initialize Listeners and Continuous Loops
function Utilities:Init()
    -- Infinite Jump Listener
    local jumpConn = UserInputService.JumpRequest:Connect(function()
        if self.InfiniteJump then
            local char = LocalPlayer.Character or self:ResolveCharacter(LocalPlayer)
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end)
    table.insert(self.Connections, jumpConn)

    -- Noclip Stepped Loop
    local steppedConn = RunService.Stepped:Connect(function()
        if self.Noclip then
            local char = LocalPlayer.Character or self:ResolveCharacter(LocalPlayer)
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
    table.insert(self.Connections, steppedConn)

    -- Physics & Hitbox Heartbeat Loop
    local heartbeatConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character or self:ResolveCharacter(LocalPlayer)
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                -- Speed Override
                if self.SpeedEnabled then
                    hum.WalkSpeed = self.SpeedValue
                end

                -- Jump Override
                if self.JumpEnabled then
                    if hum.UseJumpPower then
                        hum.JumpPower = self.JumpValue
                    else
                        hum.JumpHeight = self.JumpValue / 7
                    end
                end
            end
        end

        -- Periodic Hitbox refresh
        if self.HitboxExpanded then
            self:UpdateHitboxes()
        end

        -- Camera FOV lock
        if self.CustomFOVEnabled then
            Camera.FieldOfView = self.FOVValue
        end
    end)
    table.insert(self.Connections, heartbeatConn)

    -- Lighting Changed Safeguard
    local lightingConn = Lighting.Changed:Connect(function()
        if self.Fullbright then
            self:UpdateLighting()
        end
    end)
    table.insert(self.Connections, lightingConn)
end

-- Clean Unload
function Utilities:Destroy()
    for _, conn in ipairs(self.Connections) do
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end
    self.Connections = {}

    self:RestoreHitboxes()
    self.Fullbright = false
    self:UpdateLighting()

    self.CustomFOVEnabled = false
    self:UpdateFOV()

    -- Reset local humanoid physics to standard
    local char = LocalPlayer.Character or self:ResolveCharacter(LocalPlayer)
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            if hum.UseJumpPower then
                hum.JumpPower = 50
            else
                hum.JumpHeight = 7.2
            end
        end
    end
end

return Utilities
