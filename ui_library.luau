--[[
    Rivals Instrumentation Suite — UI Library
    Pure Luau Responsive Dark-Themed GUI Framework
    Target: Luau / Roblox Client (User-mode Executor isolated via gethui/CoreGui)
--]]

local UILibrary = {}
UILibrary.__index = UILibrary

-- Services
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Safe UI Parent Resolver
local function getSafeParent()
    if gethui then
        local success, result = pcall(gethui)
        if success and result then return result end
    end
    local success, result = pcall(function()
        return CoreGui
    end)
    if success and result then return result end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- Theme Palette
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

-- Utility: Tween Helper
local function tween(object, properties, duration, style, direction)
    local tweenInfo = TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(object, tweenInfo, properties)
    t:Play()
    return t
end

-- Utility: Make Draggable
local function makeDraggable(dragHandle, targetFrame)
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Window Constructor
function UILibrary.CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "INSTRUMENTATION SUITE"
    local windowSubtitle = config.Subtitle or "RIVALS ENGINE INSTRUMENTATION"
    local defaultKeybind = config.ToggleKey or Enum.KeyCode.RightShift

    local Window = {
        Tabs = {},
        ActiveTab = nil,
        Connections = {},
        Visible = true,
        ToggleKey = defaultKeybind
    }

    -- Root ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "InstrumentationSuite_" .. tostring(math.random(10000, 99999))
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = getSafeParent()
    Window.ScreenGui = ScreenGui

    -- Main Container Frame
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

    -- Top Bar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 48)
    TopBar.BackgroundColor3 = Theme.Sidebar
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local TopBarBottomBorder = Instance.new("Frame")
    TopBarBottomBorder.Size = UDim2.new(1, 0, 0, 1)
    TopBarBottomBorder.Position = UDim2.new(0, 0, 1, -1)
    TopBarBottomBorder.BackgroundColor3 = Theme.Border
    TopBarBottomBorder.BorderSizePixel = 0
    TopBarBottomBorder.Parent = TopBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(0, 300, 0, 24)
    TitleLabel.Position = UDim2.new(0, 18, 0, 6)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = windowTitle
    TitleLabel.TextColor3 = Theme.TextPrimary
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar

    local SubtitleLabel = Instance.new("TextLabel")
    SubtitleLabel.Name = "SubtitleLabel"
    SubtitleLabel.Size = UDim2.new(0, 300, 0, 14)
    SubtitleLabel.Position = UDim2.new(0, 18, 0, 28)
    SubtitleLabel.BackgroundTransparency = 1
    SubtitleLabel.Font = Enum.Font.Gotham
    SubtitleLabel.Text = windowSubtitle
    SubtitleLabel.TextColor3 = Theme.TextMuted
    SubtitleLabel.TextSize = 11
    SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubtitleLabel.Parent = TopBar

    -- Top Bar Action Buttons (Minimize, Close)
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 28, 0, 28)
    CloseButton.Position = UDim2.new(1, -38, 0.5, -14)
    CloseButton.BackgroundColor3 = Theme.Card
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Theme.TextSecondary
    CloseButton.TextSize = 12
    CloseButton.Parent = TopBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseButton

    CloseButton.MouseEnter:Connect(function()
        tween(CloseButton, {BackgroundColor3 = Theme.Danger, TextColor3 = Theme.TextPrimary}, 0.15)
    end)
    CloseButton.MouseLeave:Connect(function()
        tween(CloseButton, {BackgroundColor3 = Theme.Card, TextColor3 = Theme.TextSecondary}, 0.15)
    end)
    CloseButton.MouseButton1Click:Connect(function()
        Window:Destroy()
    end)

    makeDraggable(TopBar, MainFrame)

    -- Left Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 170, 1, -48)
    Sidebar.Position = UDim2.new(0, 0, 0, 48)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarRightBorder = Instance.new("Frame")
    SidebarRightBorder.Size = UDim2.new(0, 1, 1, 0)
    SidebarRightBorder.Position = UDim2.new(1, -1, 0, 0)
    SidebarRightBorder.BackgroundColor3 = Theme.Border
    SidebarRightBorder.BorderSizePixel = 0
    SidebarRightBorder.Parent = Sidebar

    local TabButtonsContainer = Instance.new("ScrollingFrame")
    TabButtonsContainer.Name = "TabButtonsContainer"
    TabButtonsContainer.Size = UDim2.new(1, -16, 1, -20)
    TabButtonsContainer.Position = UDim2.new(0, 8, 0, 10)
    TabButtonsContainer.BackgroundTransparency = 1
    TabButtonsContainer.BorderSizePixel = 0
    TabButtonsContainer.ScrollBarThickness = 2
    TabButtonsContainer.ScrollBarImageColor3 = Theme.Border
    TabButtonsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabButtonsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabButtonsContainer.Parent = Sidebar

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 6)
    TabListLayout.Parent = TabButtonsContainer

    -- Content Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -170, 1, -48)
    ContentArea.Position = UDim2.new(0, 170, 0, 48)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainFrame

    -- Global Visibility Toggle Keybind Handler
    local toggleConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Window.ToggleKey then
            Window.Visible = not Window.Visible
            MainFrame.Visible = Window.Visible
        end
    end)
    table.insert(Window.Connections, toggleConnection)

    -- Tab Creation Method
    function Window:CreateTab(tabName, tabIcon)
        local Tab = {
            Name = tabName,
            Sections = {},
            Controls = {}
        }

        -- Sidebar Tab Button
        local TabButton = Instance.new("TextButton")
        TabButton.Name = "TabBtn_" .. tabName
        TabButton.Size = UDim2.new(1, 0, 0, 36)
        TabButton.BackgroundColor3 = Theme.Sidebar
        TabButton.BackgroundTransparency = 1
        TabButton.Text = ""
        TabButton.AutoButtonColor = false
        TabButton.Parent = TabButtonsContainer

        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = UDim.new(0, 6)
        TabBtnCorner.Parent = TabButton

        local ActiveIndicator = Instance.new("Frame")
        ActiveIndicator.Name = "ActiveIndicator"
        ActiveIndicator.Size = UDim2.new(0, 3, 0, 18)
        ActiveIndicator.Position = UDim2.new(0, 4, 0.5, -9)
        ActiveIndicator.BackgroundColor3 = Theme.Accent
        ActiveIndicator.BorderSizePixel = 0
        ActiveIndicator.Visible = false
        ActiveIndicator.Parent = TabButton

        local IndicatorCorner = Instance.new("UICorner")
        IndicatorCorner.CornerRadius = UDim.new(0, 2)
        IndicatorCorner.Parent = ActiveIndicator

        local TabLabel = Instance.new("TextLabel")
        TabLabel.Name = "TabLabel"
        TabLabel.Size = UDim2.new(1, -20, 1, 0)
        TabLabel.Position = UDim2.new(0, 16, 0, 0)
        TabLabel.BackgroundTransparency = 1
        TabLabel.Font = Enum.Font.GothamMedium
        TabLabel.Text = (tabIcon and (tabIcon .. "  ") or "") .. tabName
        TabLabel.TextColor3 = Theme.TextSecondary
        TabLabel.TextSize = 13
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.Parent = TabButton

        -- Tab Content Scrolling Page
        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = "TabPage_" .. tabName
        TabPage.Size = UDim2.new(1, -24, 1, -20)
        TabPage.Position = UDim2.new(0, 12, 0, 10)
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.ScrollBarThickness = 3
        TabPage.ScrollBarImageColor3 = Theme.Border
        TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabPage.Visible = false
        TabPage.Parent = ContentArea

        local PageListLayout = Instance.new("UIListLayout")
        PageListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageListLayout.Padding = UDim.new(0, 10)
        PageListLayout.Parent = TabPage

        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingRight = UDim.new(0, 6)
        PagePadding.Parent = TabPage

        Tab.Button = TabButton
        Tab.Page = TabPage
        Tab.ActiveIndicator = ActiveIndicator
        Tab.Label = TabLabel

        local function activateTab()
            for _, otherTab in ipairs(Window.Tabs) do
                otherTab.Page.Visible = false
                otherTab.ActiveIndicator.Visible = false
                tween(otherTab.Button, {BackgroundTransparency = 1}, 0.15)
                tween(otherTab.Label, {TextColor3 = Theme.TextSecondary}, 0.15)
            end

            TabPage.Visible = true
            ActiveIndicator.Visible = true
            tween(TabButton, {BackgroundColor3 = Theme.SidebarActive, BackgroundTransparency = 0}, 0.15)
            tween(TabLabel, {TextColor3 = Theme.TextPrimary}, 0.15)
            Window.ActiveTab = Tab
        end

        TabButton.MouseButton1Click:Connect(activateTab)

        TabButton.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then
                tween(TabButton, {BackgroundTransparency = 0.5, BackgroundColor3 = Theme.SidebarActive}, 0.15)
                tween(TabLabel, {TextColor3 = Theme.TextPrimary}, 0.15)
            end
        end)

        TabButton.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then
                tween(TabButton, {BackgroundTransparency = 1}, 0.15)
                tween(TabLabel, {TextColor3 = Theme.TextSecondary}, 0.15)
            end
        end)

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then
            activateTab()
        end

        -- Section Creator
        function Tab:CreateSection(sectionTitle)
            local Section = {}

            local SectionFrame = Instance.new("Frame")
            SectionFrame.Name = "Section_" .. sectionTitle
            SectionFrame.Size = UDim2.new(1, 0, 0, 0)
            SectionFrame.AutomaticSize = Enum.AutomaticSize.Y
            SectionFrame.BackgroundColor3 = Theme.Card
            SectionFrame.BorderSizePixel = 0
            SectionFrame.Parent = TabPage

            local SectionCorner = Instance.new("UICorner")
            SectionCorner.CornerRadius = UDim.new(0, 8)
            SectionCorner.Parent = SectionFrame

            local SectionStroke = Instance.new("UIStroke")
            SectionStroke.Color = Theme.Border
            SectionStroke.Thickness = 1
            SectionStroke.Parent = SectionFrame

            local SectionPadding = Instance.new("UIPadding")
            SectionPadding.PaddingTop = UDim.new(0, 10)
            SectionPadding.PaddingBottom = UDim.new(0, 10)
            SectionPadding.PaddingLeft = UDim.new(0, 12)
            SectionPadding.PaddingRight = UDim.new(0, 12)
            SectionPadding.Parent = SectionFrame

            local SectionList = Instance.new("UIListLayout")
            SectionList.SortOrder = Enum.SortOrder.LayoutOrder
            SectionList.Padding = UDim.new(0, 8)
            SectionList.Parent = SectionFrame

            local SectionHeader = Instance.new("TextLabel")
            SectionHeader.Name = "Header"
            SectionHeader.Size = UDim2.new(1, 0, 0, 18)
            SectionHeader.BackgroundTransparency = 1
            SectionHeader.Font = Enum.Font.GothamBold
            SectionHeader.Text = string.upper(sectionTitle)
            SectionHeader.TextColor3 = Theme.AccentHover
            SectionHeader.TextSize = 11
            SectionHeader.TextXAlignment = Enum.TextXAlignment.Left
            SectionHeader.Parent = SectionFrame

            -- Toggle Control
            function Section:CreateToggle(toggleTitle, defaultValue, callback)
                local state = defaultValue or false
                callback = callback or function() end

                local ToggleContainer = Instance.new("Frame")
                ToggleContainer.Name = "Toggle_" .. toggleTitle
                ToggleContainer.Size = UDim2.new(1, 0, 0, 32)
                ToggleContainer.BackgroundTransparency = 1
                ToggleContainer.Parent = SectionFrame

                local ToggleLabel = Instance.new("TextLabel")
                ToggleLabel.Size = UDim2.new(1, -50, 1, 0)
                ToggleLabel.BackgroundTransparency = 1
                ToggleLabel.Font = Enum.Font.GothamMedium
                ToggleLabel.Text = toggleTitle
                ToggleLabel.TextColor3 = Theme.TextPrimary
                ToggleLabel.TextSize = 12
                ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                ToggleLabel.Parent = ToggleContainer

                local SwitchFrame = Instance.new("Frame")
                SwitchFrame.Size = UDim2.new(0, 38, 0, 20)
                SwitchFrame.Position = UDim2.new(1, -38, 0.5, -10)
                SwitchFrame.BackgroundColor3 = state and Theme.Accent or Theme.Sidebar
                SwitchFrame.BorderSizePixel = 0
                SwitchFrame.Parent = ToggleContainer

                local SwitchCorner = Instance.new("UICorner")
                SwitchCorner.CornerRadius = UDim.new(1, 0)
                SwitchCorner.Parent = SwitchFrame

                local SwitchStroke = Instance.new("UIStroke")
                SwitchStroke.Color = Theme.Border
                SwitchStroke.Thickness = 1
                SwitchStroke.Parent = SwitchFrame

                local Pill = Instance.new("Frame")
                Pill.Size = UDim2.new(0, 14, 0, 14)
                Pill.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                Pill.BackgroundColor3 = Theme.TextPrimary
                Pill.BorderSizePixel = 0
                Pill.Parent = SwitchFrame

                local PillCorner = Instance.new("UICorner")
                PillCorner.CornerRadius = UDim.new(1, 0)
                PillCorner.Parent = Pill

                local ClickDetector = Instance.new("TextButton")
                ClickDetector.Size = UDim2.new(1, 0, 1, 0)
                ClickDetector.BackgroundTransparency = 1
                ClickDetector.Text = ""
                ClickDetector.Parent = ToggleContainer

                local function setToggle(newState)
                    state = newState
                    local targetPos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                    local targetColor = state and Theme.Accent or Theme.Sidebar
                    tween(Pill, {Position = targetPos}, 0.18)
                    tween(SwitchFrame, {BackgroundColor3 = targetColor}, 0.18)
                    pcall(callback, state)
                end

                ClickDetector.MouseButton1Click:Connect(function()
                    setToggle(not state)
                end)

                return {
                    SetValue = setToggle,
                    GetValue = function() return state end
                }
            end

            -- Slider Control
            function Section:CreateSlider(sliderTitle, minVal, maxVal, defaultVal, callback)
                minVal = minVal or 0
                maxVal = maxVal or 100
                local currentVal = math.clamp(defaultVal or minVal, minVal, maxVal)
                callback = callback or function() end

                local SliderContainer = Instance.new("Frame")
                SliderContainer.Name = "Slider_" .. sliderTitle
                SliderContainer.Size = UDim2.new(1, 0, 0, 46)
                SliderContainer.BackgroundTransparency = 1
                SliderContainer.Parent = SectionFrame

                local LabelText = Instance.new("TextLabel")
                LabelText.Size = UDim2.new(0.7, 0, 0, 18)
                LabelText.BackgroundTransparency = 1
                LabelText.Font = Enum.Font.GothamMedium
                LabelText.Text = sliderTitle
                LabelText.TextColor3 = Theme.TextPrimary
                LabelText.TextSize = 12
                LabelText.TextXAlignment = Enum.TextXAlignment.Left
                LabelText.Parent = SliderContainer

                local ValueText = Instance.new("TextLabel")
                ValueText.Size = UDim2.new(0.3, 0, 0, 18)
                ValueText.Position = UDim2.new(0.7, 0, 0, 0)
                ValueText.BackgroundTransparency = 1
                ValueText.Font = Enum.Font.GothamBold
                ValueText.Text = tostring(math.floor(currentVal * 10) / 10)
                ValueText.TextColor3 = Theme.AccentHover
                ValueText.TextSize = 12
                ValueText.TextXAlignment = Enum.TextXAlignment.Right
                ValueText.Parent = SliderContainer

                local Track = Instance.new("Frame")
                Track.Size = UDim2.new(1, 0, 0, 6)
                Track.Position = UDim2.new(0, 0, 0, 28)
                Track.BackgroundColor3 = Theme.Sidebar
                Track.BorderSizePixel = 0
                Track.Parent = SliderContainer

                local TrackCorner = Instance.new("UICorner")
                TrackCorner.CornerRadius = UDim.new(1, 0)
                TrackCorner.Parent = Track

                local Fill = Instance.new("Frame")
                local initialPct = (currentVal - minVal) / (maxVal - minVal)
                Fill.Size = UDim2.new(initialPct, 0, 1, 0)
                Fill.BackgroundColor3 = Theme.Accent
                Fill.BorderSizePixel = 0
                Fill.Parent = Track

                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(1, 0)
                FillCorner.Parent = Fill

                local SliderHitbox = Instance.new("TextButton")
                SliderHitbox.Size = UDim2.new(1, 0, 0, 20)
                SliderHitbox.Position = UDim2.new(0, 0, 0, 20)
                SliderHitbox.BackgroundTransparency = 1
                SliderHitbox.Text = ""
                SliderHitbox.Parent = SliderContainer

                local isDragging = false

                local function updateSlider(inputX)
                    local relativeX = math.clamp(inputX - Track.AbsolutePosition.X, 0, Track.AbsoluteSize.X)
                    local pct = relativeX / Track.AbsoluteSize.X
                    local newValue = minVal + ((maxVal - minVal) * pct)
                    newValue = math.floor(newValue * 10) / 10
                    currentVal = newValue
                    Fill.Size = UDim2.new(pct, 0, 1, 0)
                    ValueText.Text = tostring(newValue)
                    pcall(callback, newValue)
                end

                SliderHitbox.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = true
                        updateSlider(input.Position.X)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateSlider(input.Position.X)
                    end
                end)

                return {
                    SetValue = function(val)
                        val = math.clamp(val, minVal, maxVal)
                        currentVal = val
                        local pct = (val - minVal) / (maxVal - minVal)
                        Fill.Size = UDim2.new(pct, 0, 1, 0)
                        ValueText.Text = tostring(val)
                        pcall(callback, val)
                    end,
                    GetValue = function() return currentVal end
                }
            end

            -- Dropdown Control
            function Section:CreateDropdown(dropdownTitle, options, defaultOption, callback)
                options = options or {}
                local selected = defaultOption or options[1] or ""
                local isExpanded = false
                callback = callback or function() end

                local DropdownContainer = Instance.new("Frame")
                DropdownContainer.Name = "Dropdown_" .. dropdownTitle
                DropdownContainer.Size = UDim2.new(1, 0, 0, 54)
                DropdownContainer.BackgroundTransparency = 1
                DropdownContainer.Parent = SectionFrame

                local LabelText = Instance.new("TextLabel")
                LabelText.Size = UDim2.new(1, 0, 0, 16)
                LabelText.BackgroundTransparency = 1
                LabelText.Font = Enum.Font.GothamMedium
                LabelText.Text = dropdownTitle
                LabelText.TextColor3 = Theme.TextPrimary
                LabelText.TextSize = 12
                LabelText.TextXAlignment = Enum.TextXAlignment.Left
                LabelText.Parent = DropdownContainer

                local HeaderBtn = Instance.new("TextButton")
                HeaderBtn.Size = UDim2.new(1, 0, 0, 30)
                HeaderBtn.Position = UDim2.new(0, 0, 0, 20)
                HeaderBtn.BackgroundColor3 = Theme.Sidebar
                HeaderBtn.Text = ""
                HeaderBtn.AutoButtonColor = false
                HeaderBtn.Parent = DropdownContainer

                local HeaderCorner = Instance.new("UICorner")
                HeaderCorner.CornerRadius = UDim.new(0, 6)
                HeaderCorner.Parent = HeaderBtn

                local HeaderStroke = Instance.new("UIStroke")
                HeaderStroke.Color = Theme.Border
                HeaderStroke.Thickness = 1
                HeaderStroke.Parent = HeaderBtn

                local SelectedText = Instance.new("TextLabel")
                SelectedText.Size = UDim2.new(1, -30, 1, 0)
                SelectedText.Position = UDim2.new(0, 10, 0, 0)
                SelectedText.BackgroundTransparency = 1
                SelectedText.Font = Enum.Font.Gotham
                SelectedText.Text = tostring(selected)
                SelectedText.TextColor3 = Theme.TextSecondary
                SelectedText.TextSize = 12
                SelectedText.TextXAlignment = Enum.TextXAlignment.Left
                SelectedText.Parent = HeaderBtn

                local ArrowIcon = Instance.new("TextLabel")
                ArrowIcon.Size = UDim2.new(0, 20, 1, 0)
                ArrowIcon.Position = UDim2.new(1, -25, 0, 0)
                ArrowIcon.BackgroundTransparency = 1
                ArrowIcon.Font = Enum.Font.GothamBold
                ArrowIcon.Text = "v"
                ArrowIcon.TextColor3 = Theme.TextMuted
                ArrowIcon.TextSize = 11
                ArrowIcon.Parent = HeaderBtn

                local OptionsFrame = Instance.new("Frame")
                OptionsFrame.Size = UDim2.new(1, 0, 0, 0)
                OptionsFrame.Position = UDim2.new(0, 0, 0, 54)
                OptionsFrame.BackgroundColor3 = Theme.Sidebar
                OptionsFrame.BorderSizePixel = 0
                OptionsFrame.ClipsDescendants = true
                OptionsFrame.Visible = false
                OptionsFrame.ZIndex = 5
                OptionsFrame.Parent = DropdownContainer

                local OptionsCorner = Instance.new("UICorner")
                OptionsCorner.CornerRadius = UDim.new(0, 6)
                OptionsCorner.Parent = OptionsFrame

                local OptionsStroke = Instance.new("UIStroke")
                OptionsStroke.Color = Theme.Border
                OptionsStroke.Thickness = 1
                OptionsStroke.Parent = OptionsFrame

                local OptionsList = Instance.new("UIListLayout")
                OptionsList.SortOrder = Enum.SortOrder.LayoutOrder
                OptionsList.Padding = UDim.new(0, 2)
                OptionsList.Parent = OptionsFrame

                local function renderOptions()
                    for _, child in ipairs(OptionsFrame:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end

                    for idx, opt in ipairs(options) do
                        local OptBtn = Instance.new("TextButton")
                        OptBtn.Size = UDim2.new(1, 0, 0, 26)
                        OptBtn.BackgroundTransparency = 1
                        OptBtn.Font = Enum.Font.Gotham
                        OptBtn.Text = "  " .. tostring(opt)
                        OptBtn.TextColor3 = (opt == selected) and Theme.AccentHover or Theme.TextSecondary
                        OptBtn.TextSize = 12
                        OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                        OptBtn.ZIndex = 6
                        OptBtn.Parent = OptionsFrame

                        OptBtn.MouseEnter:Connect(function()
                            OptBtn.BackgroundTransparency = 0.5
                            OptBtn.BackgroundColor3 = Theme.Card
                        end)
                        OptBtn.MouseLeave:Connect(function()
                            OptBtn.BackgroundTransparency = 1
                        end)
                        OptBtn.MouseButton1Click:Connect(function()
                            selected = opt
                            SelectedText.Text = tostring(opt)
                            isExpanded = false
                            OptionsFrame.Visible = false
                            DropdownContainer.Size = UDim2.new(1, 0, 0, 54)
                            ArrowIcon.Text = "v"
                            pcall(callback, selected)
                            renderOptions()
                        end)
                    end
                end

                renderOptions()

                HeaderBtn.MouseButton1Click:Connect(function()
                    isExpanded = not isExpanded
                    if isExpanded then
                        local totalHeight = #options * 28 + 6
                        OptionsFrame.Size = UDim2.new(1, 0, 0, totalHeight)
                        OptionsFrame.Visible = true
                        DropdownContainer.Size = UDim2.new(1, 0, 0, 54 + totalHeight)
                        ArrowIcon.Text = "^"
                    else
                        OptionsFrame.Visible = false
                        DropdownContainer.Size = UDim2.new(1, 0, 0, 54)
                        ArrowIcon.Text = "v"
                    end
                end)

                return {
                    SetValue = function(val)
                        selected = val
                        SelectedText.Text = tostring(val)
                        pcall(callback, val)
                    end,
                    GetValue = function() return selected end
                }
            end

            -- Keybind Selector Control
            function Section:CreateKeybind(keybindTitle, defaultKey, callback)
                local currentKey = defaultKey or Enum.KeyCode.RightShift
                local listening = false
                callback = callback or function() end

                local KeybindContainer = Instance.new("Frame")
                KeybindContainer.Name = "Keybind_" .. keybindTitle
                KeybindContainer.Size = UDim2.new(1, 0, 0, 32)
                KeybindContainer.BackgroundTransparency = 1
                KeybindContainer.Parent = SectionFrame

                local LabelText = Instance.new("TextLabel")
                LabelText.Size = UDim2.new(1, -90, 1, 0)
                LabelText.BackgroundTransparency = 1
                LabelText.Font = Enum.Font.GothamMedium
                LabelText.Text = keybindTitle
                LabelText.TextColor3 = Theme.TextPrimary
                LabelText.TextSize = 12
                LabelText.TextXAlignment = Enum.TextXAlignment.Left
                LabelText.Parent = KeybindContainer

                local KeyBtn = Instance.new("TextButton")
                KeyBtn.Size = UDim2.new(0, 80, 0, 24)
                KeyBtn.Position = UDim2.new(1, -80, 0.5, -12)
                KeyBtn.BackgroundColor3 = Theme.Sidebar
                KeyBtn.Font = Enum.Font.GothamBold
                KeyBtn.Text = currentKey.Name
                KeyBtn.TextColor3 = Theme.TextSecondary
                KeyBtn.TextSize = 11
                KeyBtn.Parent = KeybindContainer

                local KeyCorner = Instance.new("UICorner")
                KeyCorner.CornerRadius = UDim.new(0, 6)
                KeyCorner.Parent = KeyBtn

                local KeyStroke = Instance.new("UIStroke")
                KeyStroke.Color = Theme.Border
                KeyStroke.Thickness = 1
                KeyStroke.Parent = KeyBtn

                KeyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    KeyBtn.Text = "..."
                    KeyBtn.TextColor3 = Theme.AccentHover
                end)

                local bindInput = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if listening and not gameProcessed then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            currentKey = input.KeyCode
                            KeyBtn.Text = currentKey.Name
                            KeyBtn.TextColor3 = Theme.TextSecondary
                            listening = false
                            pcall(callback, currentKey)
                        end
                    end
                end)
                table.insert(Window.Connections, bindInput)

                return {
                    SetKey = function(key)
                        currentKey = key
                        KeyBtn.Text = key.Name
                        pcall(callback, key)
                    end,
                    GetKey = function() return currentKey end
                }
            end

            -- Button Control
            function Section:CreateButton(buttonTitle, callback)
                callback = callback or function() end

                local ActionBtn = Instance.new("TextButton")
                ActionBtn.Name = "Button_" .. buttonTitle
                ActionBtn.Size = UDim2.new(1, 0, 0, 30)
                ActionBtn.BackgroundColor3 = Theme.Accent
                ActionBtn.Font = Enum.Font.GothamBold
                ActionBtn.Text = buttonTitle
                ActionBtn.TextColor3 = Theme.TextPrimary
                ActionBtn.TextSize = 12
                ActionBtn.Parent = SectionFrame

                local BtnCorner = Instance.new("UICorner")
                BtnCorner.CornerRadius = UDim.new(0, 6)
                BtnCorner.Parent = ActionBtn

                ActionBtn.MouseEnter:Connect(function()
                    tween(ActionBtn, {BackgroundColor3 = Theme.AccentHover}, 0.15)
                end)
                ActionBtn.MouseLeave:Connect(function()
                    tween(ActionBtn, {BackgroundColor3 = Theme.Accent}, 0.15)
                end)
                ActionBtn.MouseButton1Click:Connect(function()
                    pcall(callback)
                end)

                return ActionBtn
            end

            -- Color Picker Control
            function Section:CreateColorPicker(colorTitle, defaultColor, callback)
                local currentColor = defaultColor or Color3.fromRGB(99, 102, 241)
                callback = callback or function() end

                local ColorContainer = Instance.new("Frame")
                ColorContainer.Name = "ColorPicker_" .. colorTitle
                ColorContainer.Size = UDim2.new(1, 0, 0, 32)
                ColorContainer.BackgroundTransparency = 1
                ColorContainer.Parent = SectionFrame

                local LabelText = Instance.new("TextLabel")
                LabelText.Size = UDim2.new(1, -40, 1, 0)
                LabelText.BackgroundTransparency = 1
                LabelText.Font = Enum.Font.GothamMedium
                LabelText.Text = colorTitle
                LabelText.TextColor3 = Theme.TextPrimary
                LabelText.TextSize = 12
                LabelText.TextXAlignment = Enum.TextXAlignment.Left
                LabelText.Parent = ColorContainer

                local ColorBox = Instance.new("TextButton")
                ColorBox.Size = UDim2.new(0, 24, 0, 24)
                ColorBox.Position = UDim2.new(1, -26, 0.5, -12)
                ColorBox.BackgroundColor3 = currentColor
                ColorBox.Text = ""
                ColorBox.Parent = ColorContainer

                local BoxCorner = Instance.new("UICorner")
                BoxCorner.CornerRadius = UDim.new(0, 6)
                BoxCorner.Parent = ColorBox

                local BoxStroke = Instance.new("UIStroke")
                BoxStroke.Color = Theme.Border
                BoxStroke.Thickness = 1
                BoxStroke.Parent = ColorBox

                -- Simple palette cycle
                local presetColors = {
                    Color3.fromRGB(99, 102, 241),  -- Indigo
                    Color3.fromRGB(239, 68, 68),   -- Red
                    Color3.fromRGB(34, 197, 94),   -- Green
                    Color3.fromRGB(234, 179, 8),   -- Yellow
                    Color3.fromRGB(168, 85, 247),  -- Purple
                    Color3.fromRGB(236, 72, 153),  -- Pink
                    Color3.fromRGB(255, 255, 255)  -- White
                }
                local colorIdx = 1

                ColorBox.MouseButton1Click:Connect(function()
                    colorIdx = (colorIdx % #presetColors) + 1
                    currentColor = presetColors[colorIdx]
                    ColorBox.BackgroundColor3 = currentColor
                    pcall(callback, currentColor)
                end)

                return {
                    SetColor = function(c)
                        currentColor = c
                        ColorBox.BackgroundColor3 = c
                        pcall(callback, c)
                    end,
                    GetColor = function() return currentColor end
                }
            end

            return Section
        end

        return Tab
    end

    -- Unload & Cleanup Method
    function Window:Destroy()
        for _, conn in ipairs(self.Connections) do
            if conn and conn.Disconnect then
                conn:Disconnect()
            end
        end
        if self.ScreenGui then
            self.ScreenGui:Destroy()
        end
    end

    return Window
end

return UILibrary
