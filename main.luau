--[[
    Rivals Instrumentation Suite — Master Unified Executable Bundle
    Single-File Standalone Instrumentation Suite with UI, Targeting, Visuals, and Utilities
    Target: Luau / Roblox Client
--]]

-- Safe Duplicate Unload
if _G.RivalsSuiteUnload then
    pcall(_G.RivalsSuiteUnload)
end

-- ==============================================================================
-- 1. CORE SERVICES & ENVIRONMENT RESOLUTION
-- ==============================================================================
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local hasDrawing = (type(Drawing) == "table" or type(Drawing) == "userdata" or type(Drawing) == "function")

local function getSafeUIParent()
    if gethui then
        local success, res = pcall(gethui)
        if success and res then return res end
    end
    local success, res = pcall(function() return CoreGui end)
    if success and res then return res end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ==============================================================================
-- 2. UI FRAMEWORK (DARK THEMED SIDEBAR LIBRARY)
-- ==============================================================================
local Theme = {
    Background = Color3.fromRGB(14, 16, 21),
    Sidebar = Color3.fromRGB(19, 23, 32),
    SidebarActive = Color3.fromRGB(28, 34, 48),
    Card = Color3.fromRGB(22, 27, 38),
    Border = Color3.fromRGB(36, 43, 59),
    Accent = Color3.fromRGB(99, 102, 241),
    AccentHover = Color3.fromRGB(129, 140, 248),
    TextPrimary = Color3.fromRGB(248, 250, 252),
    TextSecondary = Color3.fromRGB(148, 163, 184),
    TextMuted = Color3.fromRGB(100, 116, 139),
    Success = Color3.fromRGB(34, 197, 94),
    Danger = Color3.fromRGB(239, 68, 68)
}

local function tween(obj, props, duration, style, dir)
    local t = TweenService:Create(obj, TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function makeDraggable(handle, frame)
    local dragging = false
    local dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local UILib = {}
function UILib.CreateWindow(config)
    config = config or {}
    local Window = {
        Tabs = {},
        ActiveTab = nil,
        Connections = {},
        Visible = true,
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    }

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "InstrumentationSuite_" .. tostring(math.random(10000, 99999))
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = getSafeUIParent()
    Window.ScreenGui = ScreenGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 680, 0, 440)
    MainFrame.Position = UDim2.new(0.5, -340, 0.5, -220)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    Window.MainFrame = MainFrame

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Theme.Border
    MainStroke.Thickness = 1
    MainStroke.Parent = MainFrame

    -- TopBar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 48)
    TopBar.BackgroundColor3 = Theme.Sidebar
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local TopBorder = Instance.new("Frame")
    TopBorder.Size = UDim2.new(1, 0, 0, 1)
    TopBorder.Position = UDim2.new(0, 0, 1, -1)
    TopBorder.BackgroundColor3 = Theme.Border
    TopBorder.BorderSizePixel = 0
    TopBorder.Parent = TopBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(0, 320, 0, 22)
    TitleLabel.Position = UDim2.new(0, 18, 0, 7)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = config.Title or "RIVALS INSTRUMENTATION SUITE"
    TitleLabel.TextColor3 = Theme.TextPrimary
    TitleLabel.TextSize = 13
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar

    local SubtitleLabel = Instance.new("TextLabel")
    SubtitleLabel.Size = UDim2.new(0, 320, 0, 14)
    SubtitleLabel.Position = UDim2.new(0, 18, 0, 28)
    SubtitleLabel.BackgroundTransparency = 1
    SubtitleLabel.Font = Enum.Font.Gotham
    SubtitleLabel.Text = config.Subtitle or "RUNTIME REVERSE-ENGINEERING & VISUAL ENGINE"
    SubtitleLabel.TextColor3 = Theme.TextMuted
    SubtitleLabel.TextSize = 10
    SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubtitleLabel.Parent = TopBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -36, 0.5, -13)
    CloseBtn.BackgroundColor3 = Theme.Card
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Theme.TextSecondary
    CloseBtn.TextSize = 11
    CloseBtn.Parent = TopBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn

    CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, {BackgroundColor3 = Theme.Danger, TextColor3 = Theme.TextPrimary}, 0.15) end)
    CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, {BackgroundColor3 = Theme.Card, TextColor3 = Theme.TextSecondary}, 0.15) end)
    CloseBtn.MouseButton1Click:Connect(function()
        Window.Visible = false
        MainFrame.Visible = false
    end)

    makeDraggable(TopBar, MainFrame)

    -- Left Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 160, 1, -48)
    Sidebar.Position = UDim2.new(0, 0, 0, 48)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SideBorder = Instance.new("Frame")
    SideBorder.Size = UDim2.new(0, 1, 1, 0)
    SideBorder.Position = UDim2.new(1, -1, 0, 0)
    SideBorder.BackgroundColor3 = Theme.Border
    SideBorder.BorderSizePixel = 0
    SideBorder.Parent = Sidebar

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(1, -16, 1, -20)
    TabContainer.Position = UDim2.new(0, 8, 0, 10)
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.ScrollBarThickness = 2
    TabContainer.ScrollBarImageColor3 = Theme.Border
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabContainer.Parent = Sidebar

    local TabList = Instance.new("UIListLayout")
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Padding = UDim.new(0, 5)
    TabList.Parent = TabContainer

    local ContentArea = Instance.new("Frame")
    ContentArea.Size = UDim2.new(1, -160, 1, -48)
    ContentArea.Position = UDim2.new(0, 160, 0, 48)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainFrame

    local keyToggleConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Window.ToggleKey then
            Window.Visible = not Window.Visible
            MainFrame.Visible = Window.Visible
        end
    end)
    table.insert(Window.Connections, keyToggleConn)

    function Window:CreateTab(tabName, tabIcon)
        local Tab = {}

        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 36)
        TabBtn.BackgroundColor3 = Theme.Sidebar
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = ""
        TabBtn.AutoButtonColor = false
        TabBtn.Parent = TabContainer

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 6)
        TabCorner.Parent = TabBtn

        local Indicator = Instance.new("Frame")
        Indicator.Size = UDim2.new(0, 3, 0, 18)
        Indicator.Position = UDim2.new(0, 4, 0.5, -9)
        Indicator.BackgroundColor3 = Theme.Accent
        Indicator.BorderSizePixel = 0
        Indicator.Visible = false
        Indicator.Parent = TabBtn

        local IndCorner = Instance.new("UICorner")
        IndCorner.CornerRadius = UDim.new(0, 2)
        IndCorner.Parent = Indicator

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -20, 1, 0)
        Label.Position = UDim2.new(0, 16, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Font = Enum.Font.GothamMedium
        Label.Text = (tabIcon and (tabIcon .. "  ") or "") .. tabName
        Label.TextColor3 = Theme.TextSecondary
        Label.TextSize = 12
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = TabBtn

        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, -24, 1, -20)
        Page.Position = UDim2.new(0, 12, 0, 10)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Theme.Border
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.Visible = false
        Page.Parent = ContentArea

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.Parent = Page

        local PagePad = Instance.new("UIPadding")
        PagePad.PaddingRight = UDim.new(0, 6)
        PagePad.Parent = Page

        Tab.Button = TabBtn
        Tab.Page = Page
        Tab.Indicator = Indicator
        Tab.Label = Label

        local function activate()
            for _, t in ipairs(Window.Tabs) do
                t.Page.Visible = false
                t.Indicator.Visible = false
                tween(t.Button, {BackgroundTransparency = 1}, 0.15)
                tween(t.Label, {TextColor3 = Theme.TextSecondary}, 0.15)
            end
            Page.Visible = true
            Indicator.Visible = true
            tween(TabBtn, {BackgroundColor3 = Theme.SidebarActive, BackgroundTransparency = 0}, 0.15)
            tween(Label, {TextColor3 = Theme.TextPrimary}, 0.15)
            Window.ActiveTab = Tab
        end

        TabBtn.MouseButton1Click:Connect(activate)
        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then activate() end

        function Tab:CreateSection(secTitle)
            local Sec = {}
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 0)
            Frame.AutomaticSize = Enum.AutomaticSize.Y
            Frame.BackgroundColor3 = Theme.Card
            Frame.BorderSizePixel = 0
            Frame.Parent = Page

            local FCorner = Instance.new("UICorner")
            FCorner.CornerRadius = UDim.new(0, 8)
            FCorner.Parent = Frame

            local FStroke = Instance.new("UIStroke")
            FStroke.Color = Theme.Border
            FStroke.Thickness = 1
            FStroke.Parent = Frame

            local FPad = Instance.new("UIPadding")
            FPad.PaddingTop = UDim.new(0, 8)
            FPad.PaddingBottom = UDim.new(0, 8)
            FPad.PaddingLeft = UDim.new(0, 10)
            FPad.PaddingRight = UDim.new(0, 10)
            FPad.Parent = Frame

            local FList = Instance.new("UIListLayout")
            FList.SortOrder = Enum.SortOrder.LayoutOrder
            FList.Padding = UDim.new(0, 6)
            FList.Parent = Frame

            local Header = Instance.new("TextLabel")
            Header.Size = UDim2.new(1, 0, 0, 16)
            Header.BackgroundTransparency = 1
            Header.Font = Enum.Font.GothamBold
            Header.Text = string.upper(secTitle)
            Header.TextColor3 = Theme.AccentHover
            Header.TextSize = 10
            Header.TextXAlignment = Enum.TextXAlignment.Left
            Header.Parent = Frame

            function Sec:CreateToggle(title, default, cb)
                local st = default or false
                cb = cb or function() end

                local Box = Instance.new("Frame")
                Box.Size = UDim2.new(1, 0, 0, 28)
                Box.BackgroundTransparency = 1
                Box.Parent = Frame

                local Txt = Instance.new("TextLabel")
                Txt.Size = UDim2.new(1, -45, 1, 0)
                Txt.BackgroundTransparency = 1
                Txt.Font = Enum.Font.GothamMedium
                Txt.Text = title
                Txt.TextColor3 = Theme.TextPrimary
                Txt.TextSize = 12
                Txt.TextXAlignment = Enum.TextXAlignment.Left
                Txt.Parent = Box

                local Switch = Instance.new("Frame")
                Switch.Size = UDim2.new(0, 36, 0, 18)
                Switch.Position = UDim2.new(1, -36, 0.5, -9)
                Switch.BackgroundColor3 = st and Theme.Accent or Theme.Sidebar
                Switch.Parent = Box

                local SCorner = Instance.new("UICorner")
                SCorner.CornerRadius = UDim.new(1, 0)
                SCorner.Parent = Switch

                local SStroke = Instance.new("UIStroke")
                SStroke.Color = Theme.Border
                SStroke.Thickness = 1
                SStroke.Parent = Switch

                local Knob = Instance.new("Frame")
                Knob.Size = UDim2.new(0, 12, 0, 12)
                Knob.Position = st and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
                Knob.BackgroundColor3 = Theme.TextPrimary
                Knob.Parent = Switch

                local KCorner = Instance.new("UICorner")
                KCorner.CornerRadius = UDim.new(1, 0)
                KCorner.Parent = Knob

                local Btn = Instance.new("TextButton")
                Btn.Size = UDim2.new(1, 0, 1, 0)
                Btn.BackgroundTransparency = 1
                Btn.Text = ""
                Btn.Parent = Box

                local function apply(newSt)
                    st = newSt
                    local pos = st and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
                    local col = st and Theme.Accent or Theme.Sidebar
                    tween(Knob, {Position = pos}, 0.15)
                    tween(Switch, {BackgroundColor3 = col}, 0.15)
                    pcall(cb, st)
                end

                Btn.MouseButton1Click:Connect(function() apply(not st) end)
                return {SetValue = apply, GetValue = function() return st end}
            end

            function Sec:CreateSlider(title, min, max, default, cb)
                min = min or 0
                max = max or 100
                local val = math.clamp(default or min, min, max)
                cb = cb or function() end

                local Box = Instance.new("Frame")
                Box.Size = UDim2.new(1, 0, 0, 42)
                Box.BackgroundTransparency = 1
                Box.Parent = Frame

                local Txt = Instance.new("TextLabel")
                Txt.Size = UDim2.new(0.7, 0, 0, 16)
                Txt.BackgroundTransparency = 1
                Txt.Font = Enum.Font.GothamMedium
                Txt.Text = title
                Txt.TextColor3 = Theme.TextPrimary
                Txt.TextSize = 12
                Txt.TextXAlignment = Enum.TextXAlignment.Left
                Txt.Parent = Box

                local ValTxt = Instance.new("TextLabel")
                ValTxt.Size = UDim2.new(0.3, 0, 0, 16)
                ValTxt.Position = UDim2.new(0.7, 0, 0, 0)
                ValTxt.BackgroundTransparency = 1
                ValTxt.Font = Enum.Font.GothamBold
                ValTxt.Text = tostring(math.floor(val * 10) / 10)
                ValTxt.TextColor3 = Theme.AccentHover
                ValTxt.TextSize = 12
                ValTxt.TextXAlignment = Enum.TextXAlignment.Right
                ValTxt.Parent = Box

                local Track = Instance.new("Frame")
                Track.Size = UDim2.new(1, 0, 0, 5)
                Track.Position = UDim2.new(0, 0, 0, 26)
                Track.BackgroundColor3 = Theme.Sidebar
                Track.Parent = Box

                local TCorner = Instance.new("UICorner")
                TCorner.CornerRadius = UDim.new(1, 0)
                TCorner.Parent = Track

                local Fill = Instance.new("Frame")
                local pct = (val - min) / (max - min)
                Fill.Size = UDim2.new(pct, 0, 1, 0)
                Fill.BackgroundColor3 = Theme.Accent
                Fill.Parent = Track

                local FFillCorner = Instance.new("UICorner")
                FFillCorner.CornerRadius = UDim.new(1, 0)
                FFillCorner.Parent = Fill

                local Hit = Instance.new("TextButton")
                Hit.Size = UDim2.new(1, 0, 0, 16)
                Hit.Position = UDim2.new(0, 0, 0, 20)
                Hit.BackgroundTransparency = 1
                Hit.Text = ""
                Hit.Parent = Box

                local dragging = false
                local function update(inputX)
                    local relX = math.clamp(inputX - Track.AbsolutePosition.X, 0, Track.AbsoluteSize.X)
                    local p = relX / Track.AbsoluteSize.X
                    local newVal = math.floor((min + (max - min) * p) * 10) / 10
                    val = newVal
                    Fill.Size = UDim2.new(p, 0, 1, 0)
                    ValTxt.Text = tostring(newVal)
                    pcall(cb, newVal)
                end

                Hit.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        update(input.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        update(input.Position.X)
                    end
                end)

                return {
                    SetValue = function(v)
                        val = math.clamp(v, min, max)
                        local p = (val - min) / (max - min)
                        Fill.Size = UDim2.new(p, 0, 1, 0)
                        ValTxt.Text = tostring(val)
                        pcall(cb, val)
                    end
                }
            end

            function Sec:CreateDropdown(title, opts, default, cb)
                opts = opts or {}
                local sel = default or opts[1] or ""
                local open = false
                cb = cb or function() end

                local Box = Instance.new("Frame")
                Box.Size = UDim2.new(1, 0, 0, 50)
                Box.BackgroundTransparency = 1
                Box.Parent = Frame

                local Txt = Instance.new("TextLabel")
                Txt.Size = UDim2.new(1, 0, 0, 15)
                Txt.BackgroundTransparency = 1
                Txt.Font = Enum.Font.GothamMedium
                Txt.Text = title
                Txt.TextColor3 = Theme.TextPrimary
                Txt.TextSize = 12
                Txt.TextXAlignment = Enum.TextXAlignment.Left
                Txt.Parent = Box

                local Btn = Instance.new("TextButton")
                Btn.Size = UDim2.new(1, 0, 0, 28)
                Btn.Position = UDim2.new(0, 0, 0, 18)
                Btn.BackgroundColor3 = Theme.Sidebar
                Btn.Text = ""
                Btn.AutoButtonColor = false
                Btn.Parent = Box

                local BCorner = Instance.new("UICorner")
                BCorner.CornerRadius = UDim.new(0, 6)
                BCorner.Parent = Btn

                local BStroke = Instance.new("UIStroke")
                BStroke.Color = Theme.Border
                BStroke.Thickness = 1
                BStroke.Parent = Btn

                local SelTxt = Instance.new("TextLabel")
                SelTxt.Size = UDim2.new(1, -25, 1, 0)
                SelTxt.Position = UDim2.new(0, 8, 0, 0)
                SelTxt.BackgroundTransparency = 1
                SelTxt.Font = Enum.Font.Gotham
                SelTxt.Text = tostring(sel)
                SelTxt.TextColor3 = Theme.TextSecondary
                SelTxt.TextSize = 11
                SelTxt.TextXAlignment = Enum.TextXAlignment.Left
                SelTxt.Parent = Btn

                local Arrow = Instance.new("TextLabel")
                Arrow.Size = UDim2.new(0, 20, 1, 0)
                Arrow.Position = UDim2.new(1, -22, 0, 0)
                Arrow.BackgroundTransparency = 1
                Arrow.Font = Enum.Font.GothamBold
                Arrow.Text = "v"
                Arrow.TextColor3 = Theme.TextMuted
                Arrow.TextSize = 10
                Arrow.Parent = Btn

                local ListFrame = Instance.new("Frame")
                ListFrame.Size = UDim2.new(1, 0, 0, 0)
                ListFrame.Position = UDim2.new(0, 0, 0, 50)
                ListFrame.BackgroundColor3 = Theme.Sidebar
                ListFrame.BorderSizePixel = 0
                ListFrame.ClipsDescendants = true
                ListFrame.Visible = false
                ListFrame.ZIndex = 5
                ListFrame.Parent = Box

                local LCorner = Instance.new("UICorner")
                LCorner.CornerRadius = UDim.new(0, 6)
                LCorner.Parent = ListFrame

                local LStroke = Instance.new("UIStroke")
                LStroke.Color = Theme.Border
                LStroke.Thickness = 1
                LStroke.Parent = ListFrame

                local LList = Instance.new("UIListLayout")
                LList.SortOrder = Enum.SortOrder.LayoutOrder
                LList.Padding = UDim.new(0, 2)
                LList.Parent = ListFrame

                local function rebuild()
                    for _, c in ipairs(ListFrame:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    for _, opt in ipairs(opts) do
                        local OptBtn = Instance.new("TextButton")
                        OptBtn.Size = UDim2.new(1, 0, 0, 24)
                        OptBtn.BackgroundTransparency = 1
                        OptBtn.Font = Enum.Font.Gotham
                        OptBtn.Text = "  " .. tostring(opt)
                        OptBtn.TextColor3 = (opt == sel) and Theme.AccentHover or Theme.TextSecondary
                        OptBtn.TextSize = 11
                        OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                        OptBtn.ZIndex = 6
                        OptBtn.Parent = ListFrame

                        OptBtn.MouseButton1Click:Connect(function()
                            sel = opt
                            SelTxt.Text = tostring(opt)
                            open = false
                            ListFrame.Visible = false
                            Box.Size = UDim2.new(1, 0, 0, 50)
                            Arrow.Text = "v"
                            pcall(cb, sel)
                            rebuild()
                        end)
                    end
                end
                rebuild()

                Btn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        local h = #opts * 26 + 4
                        ListFrame.Size = UDim2.new(1, 0, 0, h)
                        ListFrame.Visible = true
                        Box.Size = UDim2.new(1, 0, 0, 50 + h)
                        Arrow.Text = "^"
                    else
                        ListFrame.Visible = false
                        Box.Size = UDim2.new(1, 0, 0, 50)
                        Arrow.Text = "v"
                    end
                end)

                return {SetValue = function(v) sel = v; SelTxt.Text = tostring(v); pcall(cb, v) end}
            end

            function Sec:CreateKeybind(title, defaultKey, cb)
                local cur = defaultKey or Enum.KeyCode.RightShift
                local listening = false
                cb = cb or function() end

                local Box = Instance.new("Frame")
                Box.Size = UDim2.new(1, 0, 0, 28)
                Box.BackgroundTransparency = 1
                Box.Parent = Frame

                local Txt = Instance.new("TextLabel")
                Txt.Size = UDim2.new(1, -85, 1, 0)
                Txt.BackgroundTransparency = 1
                Txt.Font = Enum.Font.GothamMedium
                Txt.Text = title
                Txt.TextColor3 = Theme.TextPrimary
                Txt.TextSize = 12
                Txt.TextXAlignment = Enum.TextXAlignment.Left
                Txt.Parent = Box

                local KBtn = Instance.new("TextButton")
                KBtn.Size = UDim2.new(0, 75, 0, 22)
                KBtn.Position = UDim2.new(1, -75, 0.5, -11)
                KBtn.BackgroundColor3 = Theme.Sidebar
                KBtn.Font = Enum.Font.GothamBold
                KBtn.Text = cur.Name
                KBtn.TextColor3 = Theme.TextSecondary
                KBtn.TextSize = 11
                KBtn.Parent = Box

                local KCorner = Instance.new("UICorner")
                KCorner.CornerRadius = UDim.new(0, 5)
                KCorner.Parent = KBtn

                local KStroke = Instance.new("UIStroke")
                KStroke.Color = Theme.Border
                KStroke.Thickness = 1
                KStroke.Parent = KBtn

                KBtn.MouseButton1Click:Connect(function()
                    listening = true
                    KBtn.Text = "..."
                    KBtn.TextColor3 = Theme.AccentHover
                end)

                local bindConn = UserInputService.InputBegan:Connect(function(input, gpe)
                    if listening and not gpe then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            cur = input.KeyCode
                            KBtn.Text = cur.Name
                            KBtn.TextColor3 = Theme.TextSecondary
                            listening = false
                            pcall(cb, cur)
                        end
                    end
                end)
                table.insert(Window.Connections, bindConn)
                return {SetKey = function(k) cur = k; KBtn.Text = k.Name; pcall(cb, k) end}
            end

            function Sec:CreateButton(title, cb)
                cb = cb or function() end
                local Btn = Instance.new("TextButton")
                Btn.Size = UDim2.new(1, 0, 0, 28)
                Btn.BackgroundColor3 = Theme.Accent
                Btn.Font = Enum.Font.GothamBold
                Btn.Text = title
                Btn.TextColor3 = Theme.TextPrimary
                Btn.TextSize = 11
                Btn.Parent = Frame

                local BCorner = Instance.new("UICorner")
                BCorner.CornerRadius = UDim.new(0, 6)
                BCorner.Parent = Btn

                Btn.MouseEnter:Connect(function() tween(Btn, {BackgroundColor3 = Theme.AccentHover}, 0.15) end)
                Btn.MouseLeave:Connect(function() tween(Btn, {BackgroundColor3 = Theme.Accent}, 0.15) end)
                Btn.MouseButton1Click:Connect(function() pcall(cb) end)
                return Btn
            end

            function Sec:CreateColorPicker(title, defaultColor, cb)
                local cur = defaultColor or Theme.Accent
                cb = cb or function() end

                local Box = Instance.new("Frame")
                Box.Size = UDim2.new(1, 0, 0, 28)
                Box.BackgroundTransparency = 1
                Box.Parent = Frame

                local Txt = Instance.new("TextLabel")
                Txt.Size = UDim2.new(1, -35, 1, 0)
                Txt.BackgroundTransparency = 1
                Txt.Font = Enum.Font.GothamMedium
                Txt.Text = title
                Txt.TextColor3 = Theme.TextPrimary
                Txt.TextSize = 12
                Txt.TextXAlignment = Enum.TextXAlignment.Left
                Txt.Parent = Box

                local CBox = Instance.new("TextButton")
                CBox.Size = UDim2.new(0, 22, 0, 22)
                CBox.Position = UDim2.new(1, -24, 0.5, -11)
                CBox.BackgroundColor3 = cur
                CBox.Text = ""
                CBox.Parent = Box

                local CBCorner = Instance.new("UICorner")
                CBCorner.CornerRadius = UDim.new(0, 5)
                CBCorner.Parent = CBox

                local CBStroke = Instance.new("UIStroke")
                CBStroke.Color = Theme.Border
                CBStroke.Thickness = 1
                CBStroke.Parent = CBox

                local palette = {
                    Color3.fromRGB(99, 102, 241),
                    Color3.fromRGB(239, 68, 68),
                    Color3.fromRGB(34, 197, 94),
                    Color3.fromRGB(234, 179, 8),
                    Color3.fromRGB(168, 85, 247),
                    Color3.fromRGB(236, 72, 153),
                    Color3.fromRGB(255, 255, 255)
                }
                local idx = 1
                CBox.MouseButton1Click:Connect(function()
                    idx = (idx % #palette) + 1
                    cur = palette[idx]
                    CBox.BackgroundColor3 = cur
                    pcall(cb, cur)
                end)
                return {SetColor = function(c) cur = c; CBox.BackgroundColor3 = c; pcall(cb, c) end}
            end

            return Sec
        end
        return Tab
    end

    function Window:Destroy()
        for _, conn in ipairs(self.Connections) do
            if conn and conn.Disconnect then conn:Disconnect() end
        end
        if self.ScreenGui then self.ScreenGui:Destroy() end
    end

    return Window
end

-- ==============================================================================
-- 3. RIVALS ENTITY RESOLUTION PIPELINE
-- ==============================================================================
local function resolvePlayerCharacter(player)
    if not player then return nil end
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        return player.Character
    end
    local charsFolder = Workspace:FindFirstChild("Characters") or Workspace:FindFirstChild("Entities")
    if charsFolder then
        local found = charsFolder:FindFirstChild(player.Name)
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

local function isPlayerTeammate(player, teamCheckEnabled)
    if not teamCheckEnabled then return false end
    if not player or not LocalPlayer then return false end
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return true
    end
    local char = resolvePlayerCharacter(player)
    local localChar = resolvePlayerCharacter(LocalPlayer)
    if char and localChar then
        local pTeam = char:GetAttribute("Team") or char:GetAttribute("TeamColor")
        local lTeam = localChar:GetAttribute("Team") or localChar:GetAttribute("TeamColor")
        if pTeam and lTeam and pTeam == lTeam then return true end
    end
    return false
end

-- ==============================================================================
-- 4. TARGETING ENGINE INSTANTIATION
-- ==============================================================================
local TargetingState = {
    Enabled = false,
    TeamCheck = true,
    WallCheck = false,
    Prediction = false,
    PredictionFactor = 0.05,
    TargetPart = "Head",
    AimMode = "Camera",
    Smoothness = 0.2,
    Priority = "Crosshair",
    ShowFOV = true,
    FOVRadius = 120,
    FOVColor = Color3.fromRGB(99, 102, 241),
    Aiming = false,
    ActivationKey = Enum.UserInputType.MouseButton2,
    Connections = {},
    FOVCircle = nil,
    OriginalNamecall = nil
}

if hasDrawing then
    local c = Drawing.new("Circle")
    c.Visible = TargetingState.ShowFOV and TargetingState.Enabled
    c.Radius = TargetingState.FOVRadius
    c.Color = TargetingState.FOVColor
    c.Thickness = 1.5
    c.Transparency = 0.85
    c.Filled = false
    c.NumSides = 64
    c.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    TargetingState.FOVCircle = c
end

local function getTargetBone(char, selectedMode)
    if not char then return nil end
    if selectedMode == "Closest" then
        local parts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
        local bestPart = nil
        local bestDist = math.huge
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        for _, pName in ipairs(parts) do
            local p = char:FindFirstChild(pName)
            if p then
                local sp, onScreen = Camera:WorldToViewportPoint(p.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestPart = p
                    end
                end
            end
        end
        return bestPart or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    elseif selectedMode == "Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    end
    return char:FindFirstChild(selectedMode) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function checkLineOfSight(origin, targetPart, targetChar)
    local dir = targetPart.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {Camera}
    local lChar = resolvePlayerCharacter(LocalPlayer)
    if lChar then table.insert(exclude, lChar) end
    params.FilterDescendantsInstances = exclude
    params.IgnoreWater = true

    local res = Workspace:Raycast(origin, dir, params)
    if not res then return true end
    if res.Instance and (res.Instance:IsDescendantOf(targetChar) or res.Instance == targetPart) then
        return true
    end
    return false
end

local function getBestTargetEntity()
    local bestTarget, bestPart = nil, nil
    local bestScore = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local camPos = Camera.CFrame.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not isPlayerTeammate(player, TargetingState.TeamCheck) then
            local char = resolvePlayerCharacter(player)
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                local hasFF = char:FindFirstChildOfClass("ForceField") ~= nil

                if hum and hum.Health > 0 and root and not hasFF then
                    local tBone = getTargetBone(char, TargetingState.TargetPart)
                    if tBone then
                        local worldPos = tBone.Position
                        if TargetingState.Prediction and root.AssemblyLinearVelocity then
                            worldPos = worldPos + (root.AssemblyLinearVelocity * TargetingState.PredictionFactor)
                        end

                        local sp, onScreen = Camera:WorldToViewportPoint(worldPos)
                        if onScreen and sp.Z > 0 then
                            local screenDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if screenDist <= TargetingState.FOVRadius then
                                local passWall = true
                                if TargetingState.WallCheck then
                                    passWall = checkLineOfSight(camPos, tBone, char)
                                end

                                if passWall then
                                    local score = (TargetingState.Priority == "Crosshair") and screenDist or (camPos - worldPos).Magnitude
                                    if score < bestScore then
                                        bestScore = score
                                        bestTarget = player
                                        bestPart = tBone
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

local function alignAim(targetPart)
    if not targetPart then return end
    local pos = targetPart.Position
    local char = targetPart.Parent
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if TargetingState.Prediction and root and root.AssemblyLinearVelocity then
        pos = pos + (root.AssemblyLinearVelocity * TargetingState.PredictionFactor)
    end

    if TargetingState.AimMode == "Camera" then
        local camPos = Camera.CFrame.Position
        local targetCFrame = CFrame.new(camPos, pos)
        local smoothFactor = math.clamp(1 - TargetingState.Smoothness, 0.05, 1)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothFactor)
    elseif TargetingState.AimMode == "Mouse" and mousemoverel then
        local sp, onScreen = Camera:WorldToViewportPoint(pos)
        if onScreen then
            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local dx = sp.X - center.X
            local dy = sp.Y - center.Y
            local smoothFactor = math.clamp(1 - TargetingState.Smoothness, 0.1, 1)
            mousemoverel(dx * smoothFactor, dy * smoothFactor)
        end
    end
end

-- Targeting Input
local targetInputBegan = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == TargetingState.ActivationKey or input.KeyCode == TargetingState.ActivationKey then
        TargetingState.Aiming = true
    end
end)
table.insert(TargetingState.Connections, targetInputBegan)

local targetInputEnded = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == TargetingState.ActivationKey or input.KeyCode == TargetingState.ActivationKey then
        TargetingState.Aiming = false
    end
end)
table.insert(TargetingState.Connections, targetInputEnded)

-- Targeting Stepped Loop
local targetRenderConn = RunService.RenderStepped:Connect(function()
    if TargetingState.FOVCircle then
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        TargetingState.FOVCircle.Position = center
        TargetingState.FOVCircle.Radius = TargetingState.FOVRadius
        TargetingState.FOVCircle.Color = TargetingState.FOVColor
        TargetingState.FOVCircle.Visible = TargetingState.ShowFOV and TargetingState.Enabled
    end

    if not TargetingState.Enabled then return end

    if TargetingState.Aiming and TargetingState.AimMode ~= "Silent" then
        local _, targetPart = getBestTargetEntity()
        if targetPart then
            alignAim(targetPart)
        end
    end
end)
table.insert(TargetingState.Connections, targetRenderConn)

-- Metamethod Interception for Silent Targeting Mode
if hookmetamethod then
    local rawMeta = getrawmetatable or debug.getmetatable
    if rawMeta then
        local gMeta = rawMeta(game)
        if gMeta then
            setreadonly(gMeta, false)
            local oldNamecall = gMeta.__namecall
            TargetingState.OriginalNamecall = oldNamecall

            hookmetamethod(game, "__namecall", newcclosure(function(selfObj, ...)
                local method = getnamecallmethod()
                local args = {...}

                if TargetingState.Enabled and TargetingState.AimMode == "Silent" then
                    if method == "Raycast" and selfObj == Workspace then
                        local _, tPart = getBestTargetEntity()
                        if tPart then
                            local origin = args[1]
                            local pos = tPart.Position
                            local char = tPart.Parent
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            if TargetingState.Prediction and root and root.AssemblyLinearVelocity then
                                pos = pos + (root.AssemblyLinearVelocity * TargetingState.PredictionFactor)
                            end
                            args[2] = (pos - origin).Unit * 1000
                            return oldNamecall(selfObj, table.unpack(args))
                        end
                    elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                        local _, tPart = getBestTargetEntity()
                        if tPart and args[1] then
                            local ray = args[1]
                            local pos = tPart.Position
                            args[1] = Ray.new(ray.Origin, (pos - ray.Origin).Unit * 1000)
                            return oldNamecall(selfObj, table.unpack(args))
                        end
                    end
                end
                return oldNamecall(selfObj, ...)
            end))
        end
    end
end

-- ==============================================================================
-- 5. VISUAL OVERLAY ENGINE INSTANTIATION
-- ==============================================================================
local VisualsState = {
    Enabled = false,
    Boxes = true,
    HealthBar = true,
    Names = true,
    Distance = true,
    Weapon = false,
    Tracers = false,
    TracerOrigin = "Bottom",
    Skeletons = false,
    Chams = false,
    TeamCheck = true,
    BoxColor = Color3.fromRGB(99, 102, 241),
    TracerColor = Color3.fromRGB(129, 140, 248),
    SkeletonColor = Color3.fromRGB(248, 250, 252),
    ChamsFillColor = Color3.fromRGB(99, 102, 241),
    ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    ChamsFillTransparency = 0.5,
    ChamsOutlineTransparency = 0,
    EntityCache = {},
    Connections = {}
}

local R15Joints = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local R6Joints = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

local function createVisualContainer(player)
    local c = {
        Player = player,
        BoxOutline = nil, Box = nil,
        HealthBarOutline = nil, HealthBar = nil,
        NameTag = nil, DistanceTag = nil, WeaponTag = nil,
        TracerLine = nil, SkeletonLines = {},
        ChamHighlight = nil
    }

    if hasDrawing then
        local bo = Drawing.new("Square")
        bo.Thickness = 3; bo.Filled = false; bo.Color = Color3.fromRGB(0, 0, 0); bo.Transparency = 0.8; bo.Visible = false
        c.BoxOutline = bo

        local b = Drawing.new("Square")
        b.Thickness = 1; b.Filled = false; b.Color = VisualsState.BoxColor; b.Transparency = 1; b.Visible = false
        c.Box = b

        local hbo = Drawing.new("Square")
        hbo.Thickness = 1; hbo.Filled = true; hbo.Color = Color3.fromRGB(0, 0, 0); hbo.Transparency = 0.7; hbo.Visible = false
        c.HealthBarOutline = hbo

        local hb = Drawing.new("Square")
        hb.Thickness = 1; hb.Filled = true; hb.Color = Color3.fromRGB(34, 197, 94); hb.Transparency = 1; hb.Visible = false
        c.HealthBar = hb

        local nt = Drawing.new("Text")
        nt.Text = player.DisplayName or player.Name; nt.Size = 13; nt.Center = true; nt.Outline = true; nt.Color = Color3.fromRGB(248, 250, 252); nt.Visible = false
        c.NameTag = nt

        local dt = Drawing.new("Text")
        dt.Text = ""; dt.Size = 11; dt.Center = true; dt.Outline = true; dt.Color = Color3.fromRGB(148, 163, 184); dt.Visible = false
        c.DistanceTag = dt

        local wt = Drawing.new("Text")
        wt.Text = ""; wt.Size = 11; wt.Center = true; wt.Outline = true; wt.Color = Color3.fromRGB(234, 179, 8); wt.Visible = false
        c.WeaponTag = wt

        local tr = Drawing.new("Line")
        tr.Thickness = 1.5; tr.Color = VisualsState.TracerColor; tr.Transparency = 0.85; tr.Visible = false
        c.TracerLine = tr

        for i = 1, 14 do
            local sl = Drawing.new("Line")
            sl.Thickness = 1.2; sl.Color = VisualsState.SkeletonColor; sl.Transparency = 0.8; sl.Visible = false
            table.insert(c.SkeletonLines, sl)
        end
    end

    VisualsState.EntityCache[player] = c
    return c
end

local function hideVisualContainer(c)
    if not c then return end
    if c.BoxOutline then c.BoxOutline.Visible = false end
    if c.Box then c.Box.Visible = false end
    if c.HealthBarOutline then c.HealthBarOutline.Visible = false end
    if c.HealthBar then c.HealthBar.Visible = false end
    if c.NameTag then c.NameTag.Visible = false end
    if c.DistanceTag then c.DistanceTag.Visible = false end
    if c.WeaponTag then c.WeaponTag.Visible = false end
    if c.TracerLine then c.TracerLine.Visible = false end
    for _, l in ipairs(c.SkeletonLines or {}) do l.Visible = false end
    if c.ChamHighlight then c.ChamHighlight.Enabled = false end
end

local function destroyVisualContainer(player)
    local c = VisualsState.EntityCache[player]
    if not c then return end
    local function rm(obj)
        if obj then pcall(function() obj.Visible = false; obj:Remove() end) end
    end
    rm(c.BoxOutline); rm(c.Box); rm(c.HealthBarOutline); rm(c.HealthBar)
    rm(c.NameTag); rm(c.DistanceTag); rm(c.WeaponTag); rm(c.TracerLine)
    for _, l in ipairs(c.SkeletonLines or {}) do rm(l) end
    if c.ChamHighlight then pcall(function() c.ChamHighlight:Destroy() end) end
    VisualsState.EntityCache[player] = nil
end

local function renderEntityVisuals(player, c)
    local char = resolvePlayerCharacter(player)
    if not char then hideVisualContainer(c); return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not root then hideVisualContainer(c); return end
    if isPlayerTeammate(player, VisualsState.TeamCheck) then hideVisualContainer(c); return end

    -- Highlights / Chams
    if VisualsState.Chams then
        if not c.ChamHighlight or c.ChamHighlight.Parent ~= char then
            pcall(function()
                if c.ChamHighlight then c.ChamHighlight:Destroy() end
                local hl = Instance.new("Highlight")
                hl.Name = "Instrumentation_Highlight"
                hl.Adornee = char
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillColor = VisualsState.ChamsFillColor
                hl.OutlineColor = VisualsState.ChamsOutlineColor
                hl.FillTransparency = VisualsState.ChamsFillTransparency
                hl.OutlineTransparency = VisualsState.ChamsOutlineTransparency
                hl.Parent = char
                c.ChamHighlight = hl
            end)
        end
        if c.ChamHighlight then
            c.ChamHighlight.Enabled = true
            c.ChamHighlight.FillColor = VisualsState.ChamsFillColor
            c.ChamHighlight.OutlineColor = VisualsState.ChamsOutlineColor
        end
    else
        if c.ChamHighlight then c.ChamHighlight.Enabled = false end
    end

    if not hasDrawing then return end

    local rootPos = root.Position
    local sp, onScreen = Camera:WorldToViewportPoint(rootPos)
    if not onScreen or sp.Z <= 0 then hideVisualContainer(c); return end

    local head = char:FindFirstChild("Head")
    local headPos = head and head.Position or (rootPos + Vector3.new(0, 2, 0))
    local topWorld = headPos + Vector3.new(0, 0.8, 0)
    local bottomWorld = rootPos - Vector3.new(0, 3.0, 0)

    local topScreen, _ = Camera:WorldToViewportPoint(topWorld)
    local bottomScreen, _ = Camera:WorldToViewportPoint(bottomWorld)

    local boxH = math.abs(bottomScreen.Y - topScreen.Y)
    local boxW = math.max(boxH * 0.65, 6)
    local boxX = sp.X - (boxW / 2)
    local boxY = topScreen.Y

    -- Box
    if VisualsState.Boxes then
        c.BoxOutline.Size = Vector2.new(boxW, boxH); c.BoxOutline.Position = Vector2.new(boxX, boxY); c.BoxOutline.Visible = true
        c.Box.Size = Vector2.new(boxW, boxH); c.Box.Position = Vector2.new(boxX, boxY); c.Box.Color = VisualsState.BoxColor; c.Box.Visible = true
    else
        c.BoxOutline.Visible = false; c.Box.Visible = false
    end

    -- HealthBar
    if VisualsState.HealthBar then
        local hpPct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local barW = 3
        local barX = boxX - barW - 3
        local barH = boxH * hpPct
        c.HealthBarOutline.Size = Vector2.new(barW + 2, boxH + 2); c.HealthBarOutline.Position = Vector2.new(barX - 1, boxY - 1); c.HealthBarOutline.Visible = true
        c.HealthBar.Size = Vector2.new(barW, barH); c.HealthBar.Position = Vector2.new(barX, boxY + (boxH - barH))
        c.HealthBar.Color = Color3.fromHSV(hpPct * 0.33, 0.85, 0.95); c.HealthBar.Visible = true
    else
        c.HealthBarOutline.Visible = false; c.HealthBar.Visible = false
    end

    -- Name
    if VisualsState.Names then
        c.NameTag.Text = player.DisplayName or player.Name
        c.NameTag.Position = Vector2.new(boxX + (boxW / 2), boxY - 15)
        c.NameTag.Visible = true
    else
        c.NameTag.Visible = false
    end

    -- Distance
    local distStuds = math.floor((Camera.CFrame.Position - rootPos).Magnitude)
    if VisualsState.Distance then
        c.DistanceTag.Text = string.format("[%d m]", math.floor(distStuds * 0.28))
        c.DistanceTag.Position = Vector2.new(boxX + (boxW / 2), boxY + boxH + 2)
        c.DistanceTag.Visible = true
    else
        c.DistanceTag.Visible = false
    end

    -- Weapon
    if VisualsState.Weapon then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            c.WeaponTag.Text = tool.Name
            c.WeaponTag.Position = Vector2.new(boxX + (boxW / 2), boxY + boxH + (VisualsState.Distance and 14 or 2))
            c.WeaponTag.Visible = true
        else
            c.WeaponTag.Visible = false
        end
    else
        c.WeaponTag.Visible = false
    end

    -- Tracers
    if VisualsState.Tracers then
        local orig
        if VisualsState.TracerOrigin == "Bottom" then
            orig = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        elseif VisualsState.TracerOrigin == "Mouse" then
            local mLoc = UserInputService:GetMouseLocation()
            orig = Vector2.new(mLoc.X, mLoc.Y)
        else
            orig = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        end
        c.TracerLine.From = orig
        c.TracerLine.To = Vector2.new(sp.X, boxY + boxH)
        c.TracerLine.Color = VisualsState.TracerColor
        c.TracerLine.Visible = true
    else
        c.TracerLine.Visible = false
    end

    -- Skeletons
    if VisualsState.Skeletons then
        local joints = (hum.RigType == Enum.HumanoidRigType.R15) and R15Joints or R6Joints
        for idx, boneLine in ipairs(c.SkeletonLines) do
            local jp = joints[idx]
            if jp then
                local pA = char:FindFirstChild(jp[1])
                local pB = char:FindFirstChild(jp[2])
                if pA and pB then
                    local pPosA, onA = Camera:WorldToViewportPoint(pA.Position)
                    local pPosB, onB = Camera:WorldToViewportPoint(pB.Position)
                    if onA and onB and pPosA.Z > 0 and pPosB.Z > 0 then
                        boneLine.From = Vector2.new(pPosA.X, pPosA.Y)
                        boneLine.To = Vector2.new(pPosB.X, pPosB.Y)
                        boneLine.Color = VisualsState.SkeletonColor
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
        for _, l in ipairs(c.SkeletonLines) do l.Visible = false end
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then createVisualContainer(p) end
end

local pAddConn = Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then createVisualContainer(p) end
end)
table.insert(VisualsState.Connections, pAddConn)

local pRemConn = Players.PlayerRemoving:Connect(function(p)
    destroyVisualContainer(p)
end)
table.insert(VisualsState.Connections, pRemConn)

local visualsRenderConn = RunService.RenderStepped:Connect(function()
    if not VisualsState.Enabled then
        for _, c in pairs(VisualsState.EntityCache) do hideVisualContainer(c) end
        return
    end
    for p, c in pairs(VisualsState.EntityCache) do
        renderEntityVisuals(p, c)
    end
end)
table.insert(VisualsState.Connections, visualsRenderConn)

-- ==============================================================================
-- 6. CLIENT UTILITIES & PHYSICS INSTRUMENTATION
-- ==============================================================================
local UtilitiesState = {
    HitboxExpanded = false,
    HitboxSize = 10,
    HitboxPart = "HumanoidRootPart",
    HitboxTransparency = 0.6,
    HitboxColor = Color3.fromRGB(99, 102, 241),
    OriginalHitboxes = {},
    SpeedEnabled = false,
    SpeedValue = 24,
    JumpEnabled = false,
    JumpValue = 60,
    InfiniteJump = false,
    Noclip = false,
    CustomFOVEnabled = false,
    FOVValue = 90,
    Fullbright = false,
    TeamCheck = true,
    OriginalLighting = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd
    },
    OriginalCameraFOV = Camera.FieldOfView,
    Connections = {}
}

local function restoreHitboxes()
    for part, orig in pairs(UtilitiesState.OriginalHitboxes) do
        if part and part.Parent then
            pcall(function()
                part.Size = orig.Size
                part.Transparency = orig.Transparency
                part.CanCollide = orig.CanCollide
                part.Material = orig.Material
            end)
        end
    end
    UtilitiesState.OriginalHitboxes = {}
end

local function updateHitboxes()
    if not UtilitiesState.HitboxExpanded then
        restoreHitboxes()
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not isPlayerTeammate(player, UtilitiesState.TeamCheck) then
            local char = resolvePlayerCharacter(player)
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local targetPart = char:FindFirstChild(UtilitiesState.HitboxPart)
                if hum and hum.Health > 0 and targetPart then
                    if not UtilitiesState.OriginalHitboxes[targetPart] then
                        UtilitiesState.OriginalHitboxes[targetPart] = {
                            Size = targetPart.Size,
                            Transparency = targetPart.Transparency,
                            CanCollide = targetPart.CanCollide,
                            Material = targetPart.Material
                        }
                    end
                    targetPart.Size = Vector3.new(UtilitiesState.HitboxSize, UtilitiesState.HitboxSize, UtilitiesState.HitboxSize)
                    targetPart.Transparency = UtilitiesState.HitboxTransparency
                    targetPart.CanCollide = false
                end
            end
        end
    end
end

local function updateLighting()
    if UtilitiesState.Fullbright then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
    else
        Lighting.Ambient = UtilitiesState.OriginalLighting.Ambient
        Lighting.OutdoorAmbient = UtilitiesState.OriginalLighting.OutdoorAmbient
        Lighting.Brightness = UtilitiesState.OriginalLighting.Brightness
        Lighting.ClockTime = UtilitiesState.OriginalLighting.ClockTime
        Lighting.FogEnd = UtilitiesState.OriginalLighting.FogEnd
    end
end

local infJumpConn = UserInputService.JumpRequest:Connect(function()
    if UtilitiesState.InfiniteJump then
        local char = LocalPlayer.Character or resolvePlayerCharacter(LocalPlayer)
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)
table.insert(UtilitiesState.Connections, infJumpConn)

local noclipConn = RunService.Stepped:Connect(function()
    if UtilitiesState.Noclip then
        local char = LocalPlayer.Character or resolvePlayerCharacter(LocalPlayer)
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end
end)
table.insert(UtilitiesState.Connections, noclipConn)

local utilHeartbeat = RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character or resolvePlayerCharacter(LocalPlayer)
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if UtilitiesState.SpeedEnabled then hum.WalkSpeed = UtilitiesState.SpeedValue end
            if UtilitiesState.JumpEnabled then
                if hum.UseJumpPower then hum.JumpPower = UtilitiesState.JumpValue else hum.JumpHeight = UtilitiesState.JumpValue / 7 end
            end
        end
    end
    if UtilitiesState.HitboxExpanded then updateHitboxes() end
    if UtilitiesState.CustomFOVEnabled then Camera.FieldOfView = UtilitiesState.FOVValue end
end)
table.insert(UtilitiesState.Connections, utilHeartbeat)

local lightChangeConn = Lighting.Changed:Connect(function()
    if UtilitiesState.Fullbright then updateLighting() end
end)
table.insert(UtilitiesState.Connections, lightChangeConn)

-- ==============================================================================
-- 7. BUILD USER INTERFACE INSTANCE & BIND CONTROLS
-- ==============================================================================
local Window = UILib.CreateWindow({
    Title = "RIVALS INSTRUMENTATION SUITE",
    Subtitle = "RUNTIME REVERSE-ENGINEERING & VISUAL ENGINE",
    ToggleKey = Enum.KeyCode.RightShift
})

-- TAB 1: TARGETING
local TabTargeting = Window:CreateTab("Targeting", "🎯")

local SecAim = TabTargeting:CreateSection("Target Alignment")
SecAim:CreateToggle("Enable Targeting Engine", false, function(st)
    TargetingState.Enabled = st
end)

SecAim:CreateDropdown("Aim Mode", {"Camera", "Mouse", "Silent"}, "Camera", function(mode)
    TargetingState.AimMode = mode
end)

SecAim:CreateDropdown("Target Bone", {"Head", "HumanoidRootPart", "Torso", "Closest"}, "Head", function(bone)
    TargetingState.TargetPart = bone
end)

SecAim:CreateDropdown("Priority Method", {"Crosshair", "Distance"}, "Crosshair", function(prio)
    TargetingState.Priority = prio
end)

SecAim:CreateSlider("Aim Smoothness", 0, 0.95, 0.2, function(val)
    TargetingState.Smoothness = val
end)

SecAim:CreateKeybind("Aim Keybind", Enum.KeyCode.E, function(key)
    TargetingState.ActivationKey = key
end)

local SecFilter = TabTargeting:CreateSection("Filters & Prediction")
SecFilter:CreateToggle("Team Check", true, function(st)
    TargetingState.TeamCheck = st
end)

SecFilter:CreateToggle("Wall Check (Line of Sight)", false, function(st)
    TargetingState.WallCheck = st
end)

SecFilter:CreateToggle("Velocity Lead Prediction", false, function(st)
    TargetingState.Prediction = st
end)

SecFilter:CreateSlider("Prediction Factor", 0.01, 0.2, 0.05, function(val)
    TargetingState.PredictionFactor = val
end)

local SecFOV = TabTargeting:CreateSection("FOV Gate")
SecFOV:CreateToggle("Draw FOV Gate Circle", true, function(st)
    TargetingState.ShowFOV = st
end)

SecFOV:CreateSlider("FOV Radius", 30, 450, 120, function(val)
    TargetingState.FOVRadius = val
end)

SecFOV:CreateColorPicker("FOV Circle Color", Color3.fromRGB(99, 102, 241), function(col)
    TargetingState.FOVColor = col
end)

-- TAB 2: VISUALS
local TabVisuals = Window:CreateTab("Visuals", "👁")

local SecOverlays = TabVisuals:CreateSection("Entity Overlays")
SecOverlays:CreateToggle("Enable Visual Engine", false, function(st)
    VisualsState.Enabled = st
end)

SecOverlays:CreateToggle("2D Bounding Boxes", true, function(st)
    VisualsState.Boxes = st
end)

SecOverlays:CreateToggle("Dynamic Health Bars", true, function(st)
    VisualsState.HealthBar = st
end)

SecOverlays:CreateToggle("Name Indicators", true, function(st)
    VisualsState.Names = st
end)

SecOverlays:CreateToggle("Distance Readout", true, function(st)
    VisualsState.Distance = st
end)

SecOverlays:CreateToggle("Equipped Tool / Weapon", false, function(st)
    VisualsState.Weapon = st
end)

SecOverlays:CreateColorPicker("Box Overlay Color", Color3.fromRGB(99, 102, 241), function(col)
    VisualsState.BoxColor = col
end)

local SecLines = TabVisuals:CreateSection("Tracers & Skeletons")
SecLines:CreateToggle("Entity Tracers", false, function(st)
    VisualsState.Tracers = st
end)

SecLines:CreateDropdown("Tracer Origin", {"Bottom", "Center", "Mouse"}, "Bottom", function(orig)
    VisualsState.TracerOrigin = orig
end)

SecLines:CreateColorPicker("Tracer Color", Color3.fromRGB(129, 140, 248), function(col)
    VisualsState.TracerColor = col
end)

SecLines:CreateToggle("Joint Skeletons", false, function(st)
    VisualsState.Skeletons = st
end)

SecLines:CreateColorPicker("Skeleton Color", Color3.fromRGB(248, 250, 252), function(col)
    VisualsState.SkeletonColor = col
end)

local SecHighlights = TabVisuals:CreateSection("Engine Highlights (Chams)")
SecHighlights:CreateToggle("Always-On-Top Chams", false, function(st)
    VisualsState.Chams = st
end)

SecHighlights:CreateColorPicker("Chams Fill Color", Color3.fromRGB(99, 102, 241), function(col)
    VisualsState.ChamsFillColor = col
end)

SecHighlights:CreateSlider("Chams Fill Transparency", 0, 1, 0.5, function(val)
    VisualsState.ChamsFillTransparency = val
end)

SecHighlights:CreateToggle("Visuals Team Check", true, function(st)
    VisualsState.TeamCheck = st
end)

-- TAB 3: UTILITIES
local TabUtilities = Window:CreateTab("Utilities", "⚡")

local SecHitbox = TabUtilities:CreateSection("Hitbox Expansion")
SecHitbox:CreateToggle("Expand Enemy Hitboxes", false, function(st)
    UtilitiesState.HitboxExpanded = st
    if not st then restoreHitboxes() end
end)

SecHitbox:CreateDropdown("Hitbox Bone", {"HumanoidRootPart", "Head"}, "HumanoidRootPart", function(bone)
    restoreHitboxes()
    UtilitiesState.HitboxPart = bone
end)

SecHitbox:CreateSlider("Hitbox Size (Studs)", 2, 30, 10, function(val)
    UtilitiesState.HitboxSize = val
end)

SecHitbox:CreateSlider("Hitbox Transparency", 0, 1, 0.6, function(val)
    UtilitiesState.HitboxTransparency = val
end)

SecHitbox:CreateToggle("Hitbox Team Check", true, function(st)
    UtilitiesState.TeamCheck = st
end)

local SecPhysics = TabUtilities:CreateSection("Client Physics Instrumentation")
SecPhysics:CreateToggle("WalkSpeed Override", false, function(st)
    UtilitiesState.SpeedEnabled = st
    if not st then
        local char = LocalPlayer.Character or resolvePlayerCharacter(LocalPlayer)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end)

SecPhysics:CreateSlider("WalkSpeed Value", 16, 120, 24, function(val)
    UtilitiesState.SpeedValue = val
end)

SecPhysics:CreateToggle("Jump Override", false, function(st)
    UtilitiesState.JumpEnabled = st
    if not st then
        local char = LocalPlayer.Character or resolvePlayerCharacter(LocalPlayer)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
        end
    end
end)

SecPhysics:CreateSlider("Jump Strength", 50, 200, 60, function(val)
    UtilitiesState.JumpValue = val
end)

SecPhysics:CreateToggle("Infinite Air Jump", false, function(st)
    UtilitiesState.InfiniteJump = st
end)

SecPhysics:CreateToggle("Noclip (Phase Collision)", false, function(st)
    UtilitiesState.Noclip = st
end)

local SecEnv = TabUtilities:CreateSection("Camera & Environment")
SecEnv:CreateToggle("Custom Field of View", false, function(st)
    UtilitiesState.CustomFOVEnabled = st
    if not st then Camera.FieldOfView = UtilitiesState.OriginalCameraFOV end
end)

SecEnv:CreateSlider("Field of View", 40, 120, 90, function(val)
    UtilitiesState.FOVValue = val
end)

SecEnv:CreateToggle("Fullbright Ambient", false, function(st)
    UtilitiesState.Fullbright = st
    updateLighting()
end)

-- TAB 4: SETTINGS & UNLOAD
local TabSettings = Window:CreateTab("Settings", "⚙")
local SecConfig = TabSettings:CreateSection("Configuration & Lifecycle")

SecConfig:CreateKeybind("Menu Visibility Toggle", Enum.KeyCode.RightShift, function(key)
    Window.ToggleKey = key
end)

-- ==============================================================================
-- 8. UNLOAD PROCEDURE & GLOBAL EXPORT
-- ==============================================================================
local function UnloadSuite()
    -- Disconnect targeting
    for _, conn in ipairs(TargetingState.Connections) do
        if conn and conn.Disconnect then conn:Disconnect() end
    end
    TargetingState.Connections = {}
    if TargetingState.FOVCircle then
        pcall(function() TargetingState.FOVCircle.Visible = false; TargetingState.FOVCircle:Remove() end)
        TargetingState.FOVCircle = nil
    end
    if TargetingState.OriginalNamecall and hookmetamethod then
        pcall(function() hookmetamethod(game, "__namecall", TargetingState.OriginalNamecall) end)
    end

    -- Disconnect visuals
    for _, conn in ipairs(VisualsState.Connections) do
        if conn and conn.Disconnect then conn:Disconnect() end
    end
    VisualsState.Connections = {}
    for p in pairs(VisualsState.EntityCache) do
        destroyVisualContainer(p)
    end
    VisualsState.EntityCache = {}

    -- Disconnect utilities
    for _, conn in ipairs(UtilitiesState.Connections) do
        if conn and conn.Disconnect then conn:Disconnect() end
    end
    UtilitiesState.Connections = {}
    restoreHitboxes()
    UtilitiesState.Fullbright = false
    updateLighting()
    UtilitiesState.CustomFOVEnabled = false
    Camera.FieldOfView = UtilitiesState.OriginalCameraFOV

    local char = LocalPlayer.Character or resolvePlayerCharacter(LocalPlayer)
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
        end
    end

    -- Destroy UI
    Window:Destroy()
    _G.RivalsSuiteUnload = nil
end

SecConfig:CreateButton("Unload Entire Suite", function()
    UnloadSuite()
end)

_G.RivalsSuiteUnload = UnloadSuite
