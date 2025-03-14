-- XVI Admin Suite
-- Main script containing the GUI library and command functionality

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Initialize local state
local AdminSuite = getgenv().XVIAdminSuite
local GUI = {}
local CommandBar = {}
local CommandHistory = {}
local HistoryIndex = 0
local CommandSuggestions = {}
local SuggestionIndex = 0
local TabPages = {}
local CurrentTab = nil
local MenuVisible = false
local CommandBarVisible = false
local Dragging = false
local DragStart = nil
local StartPos = nil

-- Utility functions
local function CreateTween(instance, properties, duration, easingStyle, easingDirection)
    local tInfo = TweenInfo.new(
        duration or 0.3,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, tInfo, properties)
    return tween
end

local function DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function FormatPlayerName(player)
    return player.Name .. " (" .. player.DisplayName .. ")"
end

local function FindPlayer(name)
    name = name:lower()
    
    -- Try exact match first
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower() == name or player.DisplayName:lower() == name then
            return player
        end
    end
    
    -- Try partial match
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower():sub(1, #name) == name or 
           player.DisplayName:lower():sub(1, #name) == name then
            return player
        end
    end
    
    return nil
end

-- Custom GUI Library
local GuiLibrary = {}

function GuiLibrary.New()
    local self = {}
    
    -- Create base GUI structure
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "XVIAdminSuiteGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Apply protection if possible
    pcall(function()
        ScreenGui.DisplayOrder = 999
        if syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
        end
    end)
    
    -- Create the main container
    local MainContainer = Instance.new("Frame")
    MainContainer.Name = "MainContainer"
    MainContainer.Size = UDim2.new(0, 600, 0, 400)
    MainContainer.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainContainer.BackgroundColor3 = AdminSuite.Config.Theme.Primary
    MainContainer.BorderSizePixel = 0
    MainContainer.ClipsDescendants = true
    MainContainer.Visible = false
    MainContainer.Parent = ScreenGui
    
    -- Round the corners
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainContainer
    
    -- Add shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 40, 1, 40)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://6015897843"
    Shadow.ImageColor3 = Color3.new(0, 0, 0)
    Shadow.ImageTransparency = 0.5
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    Shadow.ZIndex = -1
    Shadow.Parent = MainContainer
    
    -- Create title bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 36)
    TitleBar.BackgroundColor3 = AdminSuite.Config.Theme.Secondary
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainContainer
    
    local TitleBarCorner = Instance.new("UICorner")
    TitleBarCorner.CornerRadius = UDim.new(0, 8)
    TitleBarCorner.Parent = TitleBar
    
    local TitleBarFix = Instance.new("Frame")
    TitleBarFix.Name = "TitleBarFix"
    TitleBarFix.Size = UDim2.new(1, 0, 0, 10)
    TitleBarFix.Position = UDim2.new(0, 0, 1, -10)
    TitleBarFix.BackgroundColor3 = AdminSuite.Config.Theme.Secondary
    TitleBarFix.BorderSizePixel = 0
    TitleBarFix.ZIndex = 0
    TitleBarFix.Parent = TitleBar
    
    -- Title text
    local TitleText = Instance.new("TextLabel")
    TitleText.Name = "TitleText"
    TitleText.Size = UDim2.new(1, -120, 1, 0)
    TitleText.Position = UDim2.new(0, 12, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "XVI Admin Suite"
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 16
    TitleText.TextColor3 = AdminSuite.Config.Theme.Text
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar
    
    -- Close button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 36, 0, 36)
    CloseButton.Position = UDim2.new(1, -36, 0, 0)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "×"
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 24
    CloseButton.TextColor3 = AdminSuite.Config.Theme.Text
    CloseButton.Parent = TitleBar
    
    CloseButton.MouseEnter:Connect(function()
        CloseButton.TextColor3 = Color3.fromRGB(255, 100, 100)
    end)
    
    CloseButton.MouseLeave:Connect(function()
        CloseButton.TextColor3 = AdminSuite.Config.Theme.Text
    end)
    
    CloseButton.MouseButton1Click:Connect(function()
        MenuVisible = false
        local tween = CreateTween(MainContainer, {Position = UDim2.new(-0.5, 0, 0.5, -200)}, 0.3)
        tween:Play()
        tween.Completed:Connect(function()
            MainContainer.Visible = false
            MainContainer.Position = UDim2.new(0.5, -300, 0.5, -200)
        end)
    end)
    
    -- Tab bar
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(0, 150, 1, -36)
    TabContainer.Position = UDim2.new(0, 0, 0, 36)
    TabContainer.BackgroundColor3 = AdminSuite.Config.Theme.Secondary
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainContainer
    
    local TabScrollFrame = Instance.new("ScrollingFrame")
    TabScrollFrame.Name = "TabScrollFrame"
    TabScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    TabScrollFrame.BackgroundTransparency = 1
    TabScrollFrame.BorderSizePixel = 0
    TabScrollFrame.ScrollBarThickness = 4
    TabScrollFrame.ScrollBarImageColor3 = AdminSuite.Config.Theme.Accent
    TabScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    TabScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabScrollFrame.Parent = TabContainer
    
    local TabList = Instance.new("UIListLayout")
    TabList.Name = "TabList"
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Padding = UDim.new(0, 2)
    TabList.Parent = TabScrollFrame
    
    -- Content area
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -150, 1, -36)
    ContentContainer.Position = UDim2.new(0, 150, 0, 36)
    ContentContainer.BackgroundColor3 = AdminSuite.Config.Theme.Primary
    ContentContainer.BorderSizePixel = 0
    ContentContainer.ClipsDescendants = true
    ContentContainer.Parent = MainContainer
    
    -- Command bar
    local CommandBarFrame = Instance.new("Frame")
    CommandBarFrame.Name = "CommandBarFrame"
    CommandBarFrame.Size = UDim2.new(0, 500, 0, 40)
    CommandBarFrame.Position = AdminSuite.Config.CommandBarPosition
    CommandBarFrame.AnchorPoint = Vector2.new(0.5, 0)
    CommandBarFrame.BackgroundColor3 = AdminSuite.Config.Theme.Primary
    CommandBarFrame.BorderSizePixel = 0
    CommandBarFrame.Visible = false
    CommandBarFrame.Parent = ScreenGui
    
    local CommandBarCorner = Instance.new("UICorner")
    CommandBarCorner.CornerRadius = UDim.new(0, 8)
    CommandBarCorner.Parent = CommandBarFrame
    
    local CommandBarShadow = Instance.new("ImageLabel")
    CommandBarShadow.Name = "Shadow"
    CommandBarShadow.Size = UDim2.new(1, 30, 1, 30)
    CommandBarShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    CommandBarShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    CommandBarShadow.BackgroundTransparency = 1
    CommandBarShadow.Image = "rbxassetid://6015897843"
    CommandBarShadow.ImageColor3 = Color3.new(0, 0, 0)
    CommandBarShadow.ImageTransparency = 0.5
    CommandBarShadow.ScaleType = Enum.ScaleType.Slice
    CommandBarShadow.SliceCenter = Rect.new(49, 49, 450, 450)
    CommandBarShadow.ZIndex = -1
    CommandBarShadow.Parent = CommandBarFrame
    
    local CommandPrefix = Instance.new("TextLabel")
    CommandPrefix.Name = "Prefix"
    CommandPrefix.Size = UDim2.new(0, 36, 1, 0)
    CommandPrefix.BackgroundTransparency = 1
    CommandPrefix.Text = AdminSuite.Config.Prefix
    CommandPrefix.Font = Enum.Font.GothamBold
    CommandPrefix.TextSize = 18
    CommandPrefix.TextColor3 = AdminSuite.Config.Theme.Accent
    CommandPrefix.Parent = CommandBarFrame
    
    local CommandInput = Instance.new("TextBox")
    CommandInput.Name = "Input"
    CommandInput.Size = UDim2.new(1, -40, 1, 0)
    CommandInput.Position = UDim2.new(0, 36, 0, 0)
    CommandInput.BackgroundTransparency = 1
    CommandInput.Text = ""
    CommandInput.PlaceholderText = "Type a command..."
    CommandInput.Font = Enum.Font.Gotham
    CommandInput.TextSize = 16
    CommandInput.TextColor3 = AdminSuite.Config.Theme.Text
    CommandInput.TextXAlignment = Enum.TextXAlignment.Left
    CommandInput.ClipsDescendants = true
    CommandInput.ClearTextOnFocus = false
    CommandInput.Parent = CommandBarFrame
    
    -- Command suggestions
    local SuggestionsFrame = Instance.new("Frame")
    SuggestionsFrame.Name = "SuggestionsFrame"
    SuggestionsFrame.Size = UDim2.new(1, 0, 0, 0)
    SuggestionsFrame.Position = UDim2.new(0, 0, 1, 5)
    SuggestionsFrame.BackgroundColor3 = AdminSuite.Config.Theme.Primary
    SuggestionsFrame.BorderSizePixel = 0
    SuggestionsFrame.ClipsDescendants = true
    SuggestionsFrame.Visible = false
    SuggestionsFrame.ZIndex = 5
    SuggestionsFrame.Parent = CommandBarFrame
    
    local SuggestionsCorner = Instance.new("UICorner")
    SuggestionsCorner.CornerRadius = UDim.new(0, 8)
    SuggestionsCorner.Parent = SuggestionsFrame
    
    local SuggestionsShadow = Instance.new("ImageLabel")
    SuggestionsShadow.Name = "Shadow"
    SuggestionsShadow.Size = UDim2.new(1, 30, 1, 30)
    SuggestionsShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    SuggestionsShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    SuggestionsShadow.BackgroundTransparency = 1
    SuggestionsShadow.Image = "rbxassetid://6015897843"
    SuggestionsShadow.ImageColor3 = Color3.new(0, 0, 0)
    SuggestionsShadow.ImageTransparency = 0.5
    SuggestionsShadow.ScaleType = Enum.ScaleType.Slice
    SuggestionsShadow.SliceCenter = Rect.new(49, 49, 450, 450)
    SuggestionsShadow.ZIndex = 4
    SuggestionsShadow.Parent = SuggestionsFrame
    
    local SuggestionsScroll = Instance.new("ScrollingFrame")
    SuggestionsScroll.Name = "SuggestionsScroll"
    SuggestionsScroll.Size = UDim2.new(1, 0, 1, 0)
    SuggestionsScroll.BackgroundTransparency = 1
    SuggestionsScroll.BorderSizePixel = 0
    SuggestionsScroll.ScrollBarThickness = 4
    SuggestionsScroll.ScrollBarImageColor3 = AdminSuite.Config.Theme.Accent
    SuggestionsScroll.ZIndex = 6
    SuggestionsScroll.Parent = SuggestionsFrame
    
    local SuggestionsList = Instance.new("UIListLayout")
    SuggestionsList.Name = "SuggestionsList"
    SuggestionsList.SortOrder = Enum.SortOrder.LayoutOrder
    SuggestionsList.Padding = UDim.new(0, 2)
    SuggestionsList.Parent = SuggestionsScroll
    
    -- Make ScreenGui a child of PlayerGui
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Dragging functionality for main container
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            DragStart = input.Position
            StartPos = MainContainer.Position
        end
    end)
    
    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - DragStart
            MainContainer.Position = UDim2.new(
                StartPos.X.Scale,
                StartPos.X.Offset + delta.X,
                StartPos.Y.Scale,
                StartPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Command bar dragging functionality
    local DraggingCmdBar = false
    local CmdBarDragStart = nil
    local CmdBarStartPos = nil
    
    CommandPrefix.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            DraggingCmdBar = true
            CmdBarDragStart = input.Position
            CmdBarStartPos = CommandBarFrame.Position
        end
    end)
    
    CommandPrefix.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            DraggingCmdBar = false
            -- Save new position
            AdminSuite.Config.CommandBarPosition = CommandBarFrame.Position
            if AdminSuite.Config.AutoSave then
                AdminSuite.Internal.SaveConfig()
            end
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if DraggingCmdBar and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - CmdBarDragStart
            CommandBarFrame.Position = UDim2.new(
                CmdBarStartPos.X.Scale,
                CmdBarStartPos.X.Offset + delta.X,
                CmdBarStartPos.Y.Scale,
                CmdBarStartPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Command input functionality
    CommandInput.Focused:Connect(function()
        -- Show suggestions if there's text
        if #CommandInput.Text > 0 then
            self:UpdateSuggestions(CommandInput.Text)
        end
    end)
    
    CommandInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            -- Execute command
            local command = CommandInput.Text
            if #command > 0 then
                -- Add to history
                table.insert(CommandHistory, 1, command)
                if #CommandHistory > 50 then
                    table.remove(CommandHistory)
                end
                HistoryIndex = 0
                
                -- Execute
                self:ExecuteCommand(command)
                CommandInput.Text = ""
            end
        end
        
        -- Hide suggestions
        SuggestionsFrame.Visible = false
    end)
    
    CommandInput:GetPropertyChangedSignal("Text"):Connect(function()
        self:UpdateSuggestions(CommandInput.Text)
    end)
    
    -- Method to add a tab
    function self:AddTab(name, icon, order)
        -- Create tab button
        local TabButton = Instance.new("TextButton")
        TabButton.Name = name .. "Tab"
        TabButton.Size = UDim2.new(1, 0, 0, 40)
        TabButton.BackgroundTransparency = 1
        TabButton.Text = name
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 14
        TabButton.TextColor3 = AdminSuite.Config.Theme.Text
        TabButton.LayoutOrder = order or #TabScrollFrame:GetChildren()
        TabButton.Parent = TabScrollFrame
        
        -- Add icon if provided
        if icon then
            local TabIcon = Instance.new("ImageLabel")
            TabIcon.Name = "Icon"
            TabIcon.Size = UDim2.new(0, 20, 0, 20)
            TabIcon.Position = UDim2.new(0, 10, 0.5, 0)
            TabIcon.AnchorPoint = Vector2.new(0, 0.5)
            TabIcon.BackgroundTransparency = 1
            TabIcon.Image = icon
            TabIcon.Parent = TabButton
            
            -- Adjust text position
            TabButton.TextXAlignment = Enum.TextXAlignment.Right
            TabButton.TextSize = 14
        end
        
        -- Create content page
        local ContentPage = Instance.new("ScrollingFrame")
        ContentPage.Name = name .. "Page"
        ContentPage.Size = UDim2.new(1, 0, 1, 0)
        ContentPage.BackgroundTransparency = 1
        ContentPage.BorderSizePixel = 0
        ContentPage.ScrollBarThickness = 4
        ContentPage.ScrollBarImageColor3 = AdminSuite.Config.Theme.Accent
        ContentPage.Visible = false
        ContentPage.Parent = ContentContainer
        
        local ContentPadding = Instance.new("UIPadding")
        ContentPadding.PaddingLeft = UDim.new(0, 12)
        ContentPadding.PaddingRight = UDim.new(0, 12)
        ContentPadding.PaddingTop = UDim.new(0, 12)
        ContentPadding.PaddingBottom = UDim.new(0, 12)
        ContentPadding.Parent = ContentPage
        
        local ContentList = Instance.new("UIListLayout")
        ContentList.SortOrder = Enum.SortOrder.LayoutOrder
        ContentList.Padding = UDim.new(0, 8)
        ContentList.Parent = ContentPage
        
        -- Store reference to this tab
        TabPages[name] = {
            Button = TabButton,
            Page = ContentPage
        }
        
        -- Tab click handler
        TabButton.MouseButton1Click:Connect(function()
            self:SelectTab(name)
        end)
        
        -- If this is the first tab, select it
        if not CurrentTab then
            self:SelectTab(name)
        end
        
        return {
            AddSection = function(sectionName, collapsible)
                return self:AddSection(ContentPage, sectionName, collapsible)
            end
        }
    end
    
    -- Method to select a tab
    function self:SelectTab(name)
        if CurrentTab then
            -- Deselect current tab
            TabPages[CurrentTab].Button.BackgroundTransparency = 1
            TabPages[CurrentTab].Button.TextColor3 = AdminSuite.Config.Theme.Text
            TabPages[CurrentTab].Page.Visible = false
        end
        
        -- Select new tab
        CurrentTab = name
        TabPages[name].Button.BackgroundTransparency = 0.8
        TabPages[name].Button.BackgroundColor3 = AdminSuite.Config.Theme.Accent
        TabPages[name].Button.TextColor3 = Color3.new(1, 1, 1)
        TabPages[name].Page.Visible = true
    end
    
    -- Method to add a section to a tab
    function self:AddSection(parent, name, collapsible)
        local SectionFrame = Instance.new("Frame")
        SectionFrame.Name = name .. "Section"
        SectionFrame.Size = UDim2.new(1, 0, 0, 0)
        SectionFrame.BackgroundColor3 = AdminSuite.Config.Theme.Secondary
        SectionFrame.BorderSizePixel = 0
        SectionFrame.AutomaticSize = Enum.AutomaticSize.Y
        SectionFrame.Parent = parent
        
        local SectionCorner = Instance.new("UICorner")
        SectionCorner.CornerRadius = UDim.new(0, 8)
        SectionCorner.Parent = SectionFrame
        
        local SectionHeader = Instance.new("Frame")
        SectionHeader.Name = "Header"
        SectionHeader.Size = UDim2.new(1, 0, 0, 36)
        SectionHeader.BackgroundTransparency = 1
        SectionHeader.Parent = SectionFrame
        
        local SectionTitle = Instance.new("TextLabel")
        SectionTitle.Name = "Title"
        SectionTitle.Size = UDim2.new(1, -40, 1, 0)
        SectionTitle.Position = UDim2.new(0, 10, 0, 0)
        SectionTitle.BackgroundTransparency = 1
        SectionTitle.Text = name
        SectionTitle.Font = Enum.Font.GothamBold
        SectionTitle.TextSize = 14
        SectionTitle.TextColor3 = AdminSuite.Config.Theme.Text
        SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
        SectionTitle.Parent = SectionHeader
        
        local SectionContainer = Instance.new("Frame")
        SectionContainer.Name = "Container"
        SectionContainer.Size = UDim2.new(1, 0, 0, 0)
        SectionContainer.Position = UDim2.new(0, 0, 0, 36)
        SectionContainer.BackgroundTransparency = 1
        SectionContainer.AutomaticSize = Enum.AutomaticSize.Y
        SectionContainer.ClipsDescendants = false
        SectionContainer.Parent = SectionFrame
        
        local SectionPadding = Instance.new("UIPadding")
        SectionPadding.PaddingLeft = UDim.new(0, 10)
        SectionPadding.PaddingRight = UDim.new(0, 10)
        SectionPadding.PaddingBottom = UDim.new(0, 10)
        SectionPadding.Parent = SectionContainer
        
        local SectionList = Instance.new("UIListLayout")
        SectionList.SortOrder = Enum.SortOrder.LayoutOrder
        SectionList.Padding = UDim.new(0, 8)
        SectionList.Parent = SectionContainer
        
        -- Add collapse functionality if requested
        if collapsible then
            local ToggleButton = Instance.new("TextButton")
            ToggleButton.Name = "ToggleButton"
            ToggleButton.Size = UDim2.new(0, 36, 0, 36)
            ToggleButton.Position = UDim2.new(1, -36, 0, 0)
            ToggleButton.BackgroundTransparency = 1
            ToggleButton.Text = "-"
            ToggleButton.Font = Enum.Font.GothamBold
            ToggleButton.TextSize = 14
            ToggleButton.TextColor3 = AdminSuite.Config.Theme.Text
            ToggleButton.Parent = SectionHeader
            
            local collapsed = false
            
            ToggleButton.MouseButton1Click:Connect(function()
                collapsed = not collapsed
                
                if collapsed then
                    ToggleButton.Text = "+"
                    SectionContainer.Visible = false
                else
                    ToggleButton.Text = "-"
                    SectionContainer.Visible = true
                end
            end)
        end
        
        -- Return interface to add elements to this section
        return {
            AddButton = function(text, callback)
                return self:AddButton(SectionContainer, text, callback)
            end,
            AddToggle = function(text, default, callback)
                return self:AddToggle(SectionContainer, text, default, callback)
            end,
            AddSlider = function(text, min, max, default, callback)
                return self:AddSlider(SectionContainer, text, min, max, default, callback)
            end,
            AddTextBox = function(text, placeholder, default, callback)
                return self:AddTextBox(SectionContainer, text, placeholder, default, callback)
            end,
            AddDropdown = function(text, options, default, callback)
                return self:AddDropdown(SectionContainer, text, options, default, callback)
            end,
            AddColorPicker = function(text, default, callback)
                return self:AddColorPicker(SectionContainer, text, default, callback)
            end,
            AddLabel = function(text)
                return self:AddLabel(SectionContainer, text)
            end
        }
    end
    
    -- Method to add a button
    function self:AddButton(parent, text, callback)
        local ButtonFrame = Instance.new("Frame")
        ButtonFrame.Name = "ButtonFrame"
        ButtonFrame.Size = UDim2.new(1, 0, 0, 32)
        ButtonFrame.BackgroundTransparency = 1
        ButtonFrame.Parent = parent
        
        local Button = Instance.new("TextButton")
        Button.Name = "Button"
        Button.Size = UDim2.new(1, 0, 1, 0)
        Button.BackgroundColor3 = AdminSuite.Config.Theme.Accent
        Button.BackgroundTransparency = 0.7
        Button.Text = text
        Button.Font = Enum.Font.Gotham
        Button.TextSize = 14
        Button.TextColor3 = AdminSuite.Config.Theme.Text
        Button.Parent = ButtonFrame
        
        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(0, 6)
        ButtonCorner.Parent = Button
        
        -- Hover effects
        Button.MouseEnter:Connect(function()
            CreateTween(Button, {BackgroundTransparency = 0.5}, 0.2):Play()
        end)
        
        Button.MouseLeave:Connect(function()
            CreateTween(Button, {BackgroundTransparency = 0.7}, 0.2):Play()
        end)
        
        -- Click effect
        Button.MouseButton1Down:Connect(function()
            CreateTween(Button, {BackgroundTransparency = 0.3}, 0.1):Play()
        end)
        
        Button.MouseButton1Up:Connect(function()
            CreateTween(Button, {BackgroundTransparency = 0.5}, 0.1):Play()
        end)
        
        -- Click handler
        Button.MouseButton1Click:Connect(function()
            if callback then
                callback()
            end
        end)
        
        return {
            SetText = function(newText)
                Button.Text = newText
            end,
            SetCallback = function(newCallback)
                callback = newCallback
            end
        }
    end
    
    -- Method to add a toggle
    function self:AddToggle(parent, text, default, callback)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Name = "ToggleFrame"
        ToggleFrame.Size = UDim2.new(1, 0, 0, 32)
        ToggleFrame.BackgroundTransparency = 1
        ToggleFrame.Parent = parent
        
        local Label = Instance.new("TextLabel")
        Label.Name = "Label"
        Label.Size = UDim2.new(1, -60, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 14
        Label.TextColor3 = AdminSuite.Config.Theme.Text
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = ToggleFrame
        
        local ToggleBackground = Instance.new("Frame")
        ToggleBackground.Name = "Background"
        ToggleBackground.Size = UDim2.new(0, 44, 0, 24)
        ToggleBackground.Position = UDim2.new(1, -44, 0.5, 0)
        ToggleBackground.AnchorPoint = Vector2.new(0, 0.5)
        ToggleBackground.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        ToggleBackground.Parent = ToggleFrame
        
        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(1, 0)
        ToggleCorner.Parent = ToggleBackground
        
        local ToggleIndicator = Instance.new("Frame")
        ToggleIndicator.Name = "Indicator"
        ToggleIndicator.Size = UDim2.new(0, 18, 0, 18)
        ToggleIndicator.Position = UDim2.new(0, 3, 0.5, 0)
        ToggleIndicator.AnchorPoint = Vector2.new(0, 0.5)
        ToggleIndicator.BackgroundColor3 = Color3.new(1, 1, 1)
        ToggleIndicator.Parent = ToggleBackground
        
        local IndicatorCorner = Instance.new("UICorner")
        IndicatorCorner.CornerRadius = UDim.new(1, 0)
        IndicatorCorner.Parent = ToggleIndicator
        
        -- State
        local enabled = default or false
        
        -- Update visual
        local function updateToggle()
            if enabled then
                CreateTween(ToggleBackground, {BackgroundColor3 = AdminSuite.Config.Theme.Accent}, 0.2):Play()
                CreateTween(ToggleIndicator, {Position = UDim2.new(0, 23, 0.5, 0)}, 0.2):Play()
            else
                CreateTween(ToggleBackground, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}, 0.2):Play()
                CreateTween(ToggleIndicator, {Position = UDim2.new(0, 3, 0.5, 0)}, 0.2):Play()
            end
        end
        
        -- Initialize
        updateToggle()
        
        -- Click handler
        ToggleBackground.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                enabled = not enabled
                updateToggle()
                
                if callback then
                    callback(enabled)
                end
            end
        end)
        
        -- Make label also clickable
        Label.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                enabled = not enabled
                updateToggle()
                
                if callback then
                    callback(enabled)
                end
            end
        end)
        
        return {
            GetValue = function()
                return enabled
            end,
            SetValue = function(value)
                enabled = value
                updateToggle()
                if callback then
                    callback(enabled)
                end
            end,
            Toggle = function()
                enabled = not enabled
                updateToggle()
                if callback then
                    callback(enabled)
                end
            end
        }
    end
    
    -- Method to add a slider
    function self:AddSlider(parent, text, min, max, default, callback)
        local SliderFrame = Instance.new("Frame")
        SliderFrame.Name = "SliderFrame"
        SliderFrame.Size = UDim2.new(1, 0, 0, 50)
        SliderFrame.BackgroundTransparency = 1
        SliderFrame.Parent = parent
        
        local Label = Instance.new("TextLabel")
        Label.Name = "Label"
        Label.Size = UDim2.new(1, 0, 0, 20)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 14
        Label.TextColor3 = AdminSuite.Config.Theme.Text
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = SliderFrame
        
        local ValueLabel = Instance.new("TextLabel")
        ValueLabel.Name = "Value"
        ValueLabel.Size = UDim2.new(0, 50, 0, 20)
        ValueLabel.Position = UDim2.new(1, -50, 0, 0)
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Font = Enum.Font.Gotham
        ValueLabel.TextSize = 14
        ValueLabel.TextColor3 = AdminSuite.Config.Theme.Accent
        ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
        ValueLabel.Parent = SliderFrame
        
        local SliderBackground = Instance.new("Frame")
        SliderBackground.Name = "Background"
        SliderBackground.Size = UDim2.new(1, 0, 0, 8)
        SliderBackground.Position = UDim2.new(0, 0, 0, 30)
        SliderBackground.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        SliderBackground.Parent = SliderFrame
        
        local BackgroundCorner = Instance.new("UICorner")
        BackgroundCorner.CornerRadius = UDim.new(1, 0)
        BackgroundCorner.Parent = SliderBackground
        
        local SliderFill = Instance.new("Frame")
        SliderFill.Name = "Fill"
        SliderFill.BackgroundColor3 = AdminSuite.Config.Theme.Accent
        SliderFill.Size = UDim2.new(0, 0, 1, 0)
        SliderFill.Parent = SliderBackground
        
        local FillCorner = Instance.new("UICorner")
        FillCorner.CornerRadius = UDim.new(1, 0)
        FillCorner.Parent = SliderFill
        
        local SliderButton = Instance.new("TextButton")
        SliderButton.Name = "SliderButton"
        SliderButton.Size = UDim2.new(0, 16, 0, 16)
        SliderButton.Position = UDim2.new(0, 0, 0, 30)
        SliderButton.AnchorPoint = Vector2.new(0.5, 0.5)
        SliderButton.BackgroundColor3 = Color3.new(1, 1, 1)
        SliderButton.Text = ""
        SliderButton.Parent = SliderFrame
        
        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(1, 0)
        ButtonCorner.Parent = SliderButton
        
        -- State
        local value = default or min
        local dragging = false
        
        -- Update visual
        local function updateSlider()
            local percent = (value - min) / (max - min)
            SliderFill.Size = UDim2.new(percent, 0, 1, 0)
            SliderButton.Position = UDim2.new(percent, 0, 0, 30)
            ValueLabel.Text = tostring(math.floor(value * 100) / 100)
        end
        
        -- Initialize
        updateSlider()
        
        -- Input handlers
        SliderButton.MouseButton1Down:Connect(function()
            dragging = true
        end)
        
        SliderBackground.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                
                -- Calculate value from click position
                local percentX = math.clamp((input.Position.X - SliderBackground.AbsolutePosition.X) / SliderBackground.AbsoluteSize.X, 0, 1)
                value = min + (max - min) * percentX
                
                updateSlider()
                
                if callback then
                    callback(value)
                end
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                -- Calculate value from mouse position
                local percentX = math.clamp((input.Position.X - SliderBackground.AbsolutePosition.X) / SliderBackground.AbsoluteSize.X, 0, 1)
                value = min + (max - min) * percentX
                
                updateSlider()
                
                if callback then
                    callback(value)
                end
            end
        end)
        
        return {
            GetValue = function()
                return value
            end,
            SetValue = function(newValue)
                value = math.clamp(newValue, min, max)
                updateSlider()
                if callback then
                    callback(value)
                end
            end,
            SetLimits = function(newMin, newMax)
                min = newMin
                max = newMax
                value = math.clamp(value, min, max)
                updateSlider()
                if callback then
                    callback(value)
                end
            end
        }
    end
    
    -- Method to add a textbox
    function self:AddTextBox(parent, text, placeholder, default, callback)
        local TextBoxFrame = Instance.new("Frame")
        TextBoxFrame.Name = "TextBoxFrame"
        TextBoxFrame.Size = UDim2.new(1, 0, 0, 50)
        TextBoxFrame.BackgroundTransparency = 1
        TextBoxFrame.Parent = parent
        
        local Label = Instance.new("TextLabel")
        Label.Name = "Label"
        Label.Size = UDim2.new(1, 0, 0, 20)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 14
        Label.TextColor3 = AdminSuite.Config.Theme.Text
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = TextBoxFrame
        
        local TextBoxContainer = Instance.new("Frame")
        TextBoxContainer.Name = "Container"
        TextBoxContainer.Size = UDim2.new(1, 0, 0, 30)
        TextBoxContainer.Position = UDim2.new(0, 0, 0, 20)
        TextBoxContainer.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        TextBoxContainer.Parent = TextBoxFrame
        
        local ContainerCorner = Instance.new("UICorner")
        ContainerCorner.CornerRadius = UDim.new(0, 6)
        ContainerCorner.Parent = TextBoxContainer
        
        local TextBox = Instance.new("TextBox")
        TextBox.Name = "TextBox"
        TextBox.Size = UDim2.new(1, -12, 1, 0)
        TextBox.Position = UDim2.new(0, 6, 0, 0)
        TextBox.BackgroundTransparency = 1
        TextBox.Text = default or ""
        TextBox.PlaceholderText = placeholder or ""
        TextBox.Font = Enum.Font.Gotham
        TextBox.TextSize = 14
        TextBox.TextColor3 = AdminSuite.Config.Theme.Text
        TextBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
        TextBox.ClearTextOnFocus = false
        TextBox.Parent = TextBoxContainer
        
        -- Focus effects
        TextBox.Focused:Connect(function()
            CreateTween(TextBoxContainer, {BackgroundColor3 = Color3.fromRGB(80, 80, 100)}, 0.2):Play()
        end)
        
        TextBox.FocusLost:Connect(function(enterPressed)
            CreateTween(TextBoxContainer, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}, 0.2):Play()
            
            if enterPressed and callback then
                callback(TextBox.Text)
            end
        end)
        
        return {
            GetText = function()
                return TextBox.Text
            end,
            SetText = function(newText)
                TextBox.Text = newText
                if callback then
                    callback(newText)
                end
            end,
            OnChange = function(newCallback)
                TextBox:GetPropertyChangedSignal("Text"):Connect(function()
                    newCallback(TextBox.Text)
                end)
            end
        }
    end
    
    -- Method to add a dropdown
    function self:AddDropdown(parent, text, options, default, callback)
        local DropdownFrame = Instance.new("Frame")
        DropdownFrame.Name = "DropdownFrame"
        DropdownFrame.Size = UDim2.new(1, 0, 0, 50)
        DropdownFrame.BackgroundTransparency = 1
        DropdownFrame.ClipsDescendants = true
        DropdownFrame.Parent = parent
        
        local Label = Instance.new("TextLabel")
        Label.Name = "Label"
        Label.Size = UDim2.new(1, 0, 0, 20)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 14
        Label.TextColor3 = AdminSuite.Config.Theme.Text
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = DropdownFrame
        
        local DropdownButton = Instance.new("TextButton")
        DropdownButton.Name = "Button"
        DropdownButton.Size = UDim2.new(1, 0, 0, 30)
        DropdownButton.Position = UDim2.new(0, 0, 0, 20)
        DropdownButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        DropdownButton.Text = default or "Select..."
        DropdownButton.Font = Enum.Font.Gotham
        DropdownButton.TextSize = 14
        DropdownButton.TextColor3 = AdminSuite.Config.Theme.Text
        DropdownButton.TextXAlignment = Enum.TextXAlignment.Left
        DropdownButton.TextTruncate = Enum.TextTruncate.AtEnd
        DropdownButton.Parent = DropdownFrame
        
        local ButtonPadding = Instance.new("UIPadding")
        ButtonPadding.PaddingLeft = UDim.new(0, 10)
        ButtonPadding.Parent = DropdownButton
        
        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(0, 6)
        ButtonCorner.Parent = DropdownButton
        
        local ArrowIcon = Instance.new("TextLabel")
        ArrowIcon.Name = "Arrow"
        ArrowIcon.Size = UDim2.new(0, 20, 0, 20)
        ArrowIcon.Position = UDim2.new(1, -25, 0.5, 0)
        ArrowIcon.AnchorPoint = Vector2.new(0, 0.5)
        ArrowIcon.BackgroundTransparency = 1
        ArrowIcon.Text = "▼"
        ArrowIcon.Font = Enum.Font.Gotham
        ArrowIcon.TextSize = 14
        ArrowIcon.TextColor3 = AdminSuite.Config.Theme.Text
        ArrowIcon.Parent = DropdownButton
        
        local OptionContainer = Instance.new("Frame")
        OptionContainer.Name = "OptionContainer"
        OptionContainer.Size = UDim2.new(1, 0, 0, 0)
        OptionContainer.Position = UDim2.new(0, 0, 0, 50)
        OptionContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        OptionContainer.ZIndex = 2
        OptionContainer.Visible = false
        OptionContainer.Parent = DropdownFrame
        
        local ContainerCorner = Instance.new("UICorner")
        ContainerCorner.CornerRadius = UDim.new(0, 6)
        ContainerCorner.Parent = OptionContainer
        
        local OptionList = Instance.new("UIListLayout")
        OptionList.SortOrder = Enum.SortOrder.LayoutOrder
        OptionList.Parent = OptionContainer
        
        -- State
        local selected = default
        local open = false
        
        -- Create options
        local function createOptions()
            -- Clear existing options
            for _, child in pairs(OptionContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            -- Create new options
            for i, option in ipairs(options) do
                local OptionButton = Instance.new("TextButton")
                OptionButton.Name = "Option_" .. i
                OptionButton.Size = UDim2.new(1, 0, 0, 30)
                OptionButton.BackgroundTransparency = 1
                OptionButton.Text = option
                OptionButton.Font = Enum.Font.Gotham
                OptionButton.TextSize = 14
                OptionButton.TextColor3 = AdminSuite.Config.Theme.Text
                OptionButton.TextXAlignment = Enum.TextXAlignment.Left
                OptionButton.ZIndex = 3
                OptionButton.Parent = OptionContainer
                
                local OptionPadding = Instance.new("UIPadding")
                OptionPadding.PaddingLeft = UDim.new(0, 10)
                OptionPadding.Parent = OptionButton
                
                -- Click handler
                OptionButton.MouseButton1Click:Connect(function()
                    selected = option
                    DropdownButton.Text = option
                    
                    -- Close dropdown
                    open = false
                    OptionContainer.Visible = false
                    CreateTween(ArrowIcon, {Rotation = 0}, 0.2):Play()
                    CreateTween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 50)}, 0.2):Play()
                    
                    if callback then
                        callback(option)
                    end
                end)
                
                -- Hover effect
                OptionButton.MouseEnter:Connect(function()
                    CreateTween(OptionButton, {BackgroundTransparency = 0.8}, 0.1):Play()
                end)
                
                OptionButton.MouseLeave:Connect(function()
                    CreateTween(OptionButton, {BackgroundTransparency = 1}, 0.1):Play()
                end)
            end
        end
        
        -- Initialize options
        createOptions()
        
        -- Toggle dropdown
        DropdownButton.MouseButton1Click:Connect(function()
            open = not open
            
            if open then
                -- Open dropdown
                OptionContainer.Visible = true
                local contentHeight = OptionList.AbsoluteContentSize.Y
                local targetHeight = math.min(contentHeight, 150) -- Max height of dropdown
                
                CreateTween(ArrowIcon, {Rotation = 180}, 0.2):Play()
                CreateTween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 50 + targetHeight)}, 0.2):Play()
                CreateTween(OptionContainer, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.2):Play()
            else
                -- Close dropdown
                CreateTween(ArrowIcon, {Rotation = 0}, 0.2):Play()
                CreateTween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 50)}, 0.2):Play()
                
                task.delay(0.2, function()
                    if not open then
                        OptionContainer.Visible = false
                    end
                end)
            end
        end)
        
        return {
            GetSelected = function()
                return selected
            end,
            SetOptions = function(newOptions)
                options = newOptions
                createOptions()
            end,
            SetSelected = function(option)
                if table.find(options, option) then
                    selected = option
                    DropdownButton.Text = option
                    
                    if callback then
                        callback(option)
                    end
                end
            end
        }
    end
    
    -- Method to add a color picker
    function self:AddColorPicker(parent, text, default, callback)
        local ColorPickerFrame = Instance.new("Frame")
        ColorPickerFrame.Name = "ColorPickerFrame"
        ColorPickerFrame.Size = UDim2.new(1, 0, 0, 50)
        ColorPickerFrame.BackgroundTransparency = 1
        ColorPickerFrame.Parent = parent
        
        local Label = Instance.new("TextLabel")
        Label.Name = "Label"
        Label.Size = UDim2.new(1, -60, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 14
        Label.TextColor3 = AdminSuite.Config.Theme.Text
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = ColorPickerFrame
        
        local ColorDisplay = Instance.new("TextButton")
        ColorDisplay.Name = "ColorDisplay"
        ColorDisplay.Size = UDim2.new(0, 40, 0, 40)
        ColorDisplay.Position = UDim2.new(1, -40, 0.5, 0)
        ColorDisplay.AnchorPoint = Vector2.new(0, 0.5)
        ColorDisplay.BackgroundColor3 = default or Color3.new(1, 1, 1)
        ColorDisplay.Text = ""
        ColorDisplay.Parent = ColorPickerFrame
        
        local DisplayCorner = Instance.new("UICorner")
        DisplayCorner.CornerRadius = UDim.new(0, 8)
        DisplayCorner.Parent = ColorDisplay
        
        -- Create detailed color picker panel
        local PickerPanel = Instance.new("Frame")
        PickerPanel.Name = "PickerPanel"
        PickerPanel.Size = UDim2.new(0, 200, 0, 220)
        PickerPanel.Position = UDim2.new(1, -200, 0, 50)
        PickerPanel.BackgroundColor3 = AdminSuite.Config.Theme.Secondary
        PickerPanel.BorderSizePixel = 0
        PickerPanel.Visible = false
        PickerPanel.ZIndex = 10
        PickerPanel.Parent = ColorPickerFrame
        
        local PanelCorner = Instance.new("UICorner")
        PanelCorner.CornerRadius = UDim.new(0, 8)
        PanelCorner.Parent = PickerPanel
        
        -- Color picker implementation is simplified here
        -- In a full implementation, you would include:
        -- 1. A hue slider
        -- 2. A saturation/value selector
        -- 3. RGB inputs
        -- 4. Hex input
        
        -- For brevity, we'll just include a simplified version with RGB sliders
        
        local RSlider = Instance.new("Frame")
        RSlider.Name = "RSlider"
        RSlider.Size = UDim2.new(1, -20, 0, 30)
        RSlider.Position = UDim2.new(0, 10, 0, 10)
        RSlider.BackgroundTransparency = 1
        RSlider.ZIndex = 11
        RSlider.Parent = PickerPanel
        
        local RLabel = Instance.new("TextLabel")
        RLabel.Name = "RLabel"
        RLabel.Size = UDim2.new(0, 20, 1, 0)
        RLabel.BackgroundTransparency = 1
        RLabel.Text = "R:"
        RLabel.Font = Enum.Font.Gotham
        RLabel.TextSize = 14
        RLabel.TextColor3 = Color3.new(1, 0, 0)
        RLabel.ZIndex = 11
        RLabel.Parent = RSlider
        
        local R = self:AddSlider(RSlider, "", 0, 255, default and math.floor(default.R * 255) or 255, function(value)
            local current = ColorDisplay.BackgroundColor3
            ColorDisplay.BackgroundColor3 = Color3.fromRGB(value, current.G * 255, current.B * 255)
            
            if callback then
                callback(ColorDisplay.BackgroundColor3)
            end
        end)
        
        local GSlider = Instance.new("Frame")
        GSlider.Name = "GSlider"
        GSlider.Size = UDim2.new(1, -20, 0, 30)
        GSlider.Position = UDim2.new(0, 10, 0, 50)
        GSlider.BackgroundTransparency = 1
        GSlider.ZIndex = 11
        GSlider.Parent = PickerPanel
        
        local GLabel = Instance.new("TextLabel")
        GLabel.Name = "GLabel"
        GLabel.Size = UDim2.new(0, 20, 1, 0)
        GLabel.BackgroundTransparency = 1
        GLabel.Text = "G:"
        GLabel.Font = Enum.Font.Gotham
        GLabel.TextSize = 14
        GLabel.TextColor3 = Color3.new(0, 1, 0)
        GLabel.ZIndex = 11
        GLabel.Parent = GSlider
        
        local G = self:AddSlider(GSlider, "", 0, 255, default and math.floor(default.G * 255) or 255, function(value)
            local current = ColorDisplay.BackgroundColor3
            ColorDisplay.BackgroundColor3 = Color3.fromRGB(current.R * 255, value, current.B * 255)
            
            if callback then
                callback(ColorDisplay.BackgroundColor3)
            end
        end)
        
        local BSlider = Instance.new("Frame")
        BSlider.Name = "BSlider"
        BSlider.Size = UDim2.new(1, -20, 0, 30)
        BSlider.Position = UDim2.new(0, 10, 0, 90)
        BSlider.BackgroundTransparency = 1
        BSlider.ZIndex = 11
        BSlider.Parent = PickerPanel
        
        local BLabel = Instance.new("TextLabel")
        BLabel.Name = "BLabel"
        BLabel.Size = UDim2.new(0, 20, 1, 0)
        BLabel.BackgroundTransparency = 1
        BLabel.Text = "B:"
        BLabel.Font = Enum.Font.Gotham
        BLabel.TextSize = 14
        BLabel.TextColor3 = Color3.new(0, 0, 1)
        BLabel.ZIndex = 11
        BLabel.Parent = BSlider
        
        local B = self:AddSlider(BSlider, "", 0, 255, default and math.floor(default.B * 255) or 255, function(value)
            local current = ColorDisplay.BackgroundColor3
            ColorDisplay.BackgroundColor3 = Color3.fromRGB(current.R * 255, current.G * 255, value)
            
            if callback then
                callback(ColorDisplay.BackgroundColor3)
            end
        end)
        
        -- Apply button
        local ApplyButton = Instance.new("TextButton")
        ApplyButton.Name = "ApplyButton"
        ApplyButton.Size = UDim2.new(1, -20, 0, 30)
        ApplyButton.Position = UDim2.new(0, 10, 1, -40)
        ApplyButton.BackgroundColor3 = AdminSuite.Config.Theme.Accent
        ApplyButton.Text = "Apply"
        ApplyButton.Font = Enum.Font.GothamBold
        ApplyButton.TextSize = 14
        ApplyButton.TextColor3 = Color3.new(1, 1, 1)
        ApplyButton.ZIndex = 11
        ApplyButton.Parent = PickerPanel
        
        local ApplyCorner = Instance.new("UICorner")
        ApplyCorner.CornerRadius = UDim.new(0, 6)
        ApplyCorner.Parent = ApplyButton
        
        ApplyButton.MouseButton1Click:Connect(function()
            PickerPanel.Visible = false
            
            if callback then
                callback(ColorDisplay.BackgroundColor3)
            end
        end)
        
        -- Toggle color picker panel
        ColorDisplay.MouseButton1Click:Connect(function()
            PickerPanel.Visible = not PickerPanel.Visible
        end)
        
        return {
            GetColor = function()
                return ColorDisplay.BackgroundColor3
            end,
            SetColor = function(color)
                ColorDisplay.BackgroundColor3 = color
                R.SetValue(color.R * 255)
                G.SetValue(color.G * 255)
                B.SetValue(color.B * 255)
                
                if callback then
                    callback(color)
                end
            end
        }
    end
    
    -- Method to add a label
    function self:AddLabel(parent, text)
        local LabelFrame = Instance.new("Frame")
        LabelFrame.Name = "LabelFrame"
        LabelFrame.Size = UDim2.new(1, 0, 0, 30)
        LabelFrame.BackgroundTransparency = 1
        LabelFrame.Parent = parent
        
        local Label = Instance.new("TextLabel")
        Label.Name = "Label"
        Label.Size = UDim2.new(1, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 14
        Label.TextColor3 = AdminSuite.Config.Theme.Text
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextWrapped = true
        Label.Parent = LabelFrame
        
        return {
            SetText = function(newText)
                Label.Text = newText
            end
        }
    end
    
    -- Command execution logic
    function self:UpdateSuggestions(input)
        -- Clear existing suggestions
        for _, child in pairs(SuggestionsScroll:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        if #input == 0 then
            SuggestionsFrame.Visible = false
            SuggestionIndex = 0
            return
        end
        
        -- Find matching commands
        local matches = {}
        for _, cmd in pairs(AdminSuite.Commands) do
            if cmd.Name:lower():find(input:lower(), 1, true) then
                table.insert(matches, cmd)
            end
        end
        
        CommandSuggestions = matches
        
        if #matches == 0 then
            SuggestionsFrame.Visible = false
            SuggestionIndex = 0
            return
        end
        
        -- Sort matches by relevance
        table.sort(matches, function(a, b)
            local aStart = a.Name:lower():find(input:lower(), 1, true) or 999
            local bStart = b.Name:lower():find(input:lower(), 1, true) or 999
            if aStart == bStart then
                return a.Name < b.Name
            end
            return aStart < bStart
        end)
        
        -- Create suggestion buttons
        for i, cmd in ipairs(matches) do
            local SuggestionButton = Instance.new("TextButton")
            SuggestionButton.Name = "Suggestion_" .. i
            SuggestionButton.Size = UDim2.new(1, 0, 0, 30)
            SuggestionButton.BackgroundTransparency = 1
            SuggestionButton.Text = cmd.Name
            SuggestionButton.Font = Enum.Font.Gotham
            SuggestionButton.TextSize = 14
            SuggestionButton.TextColor3 = AdminSuite.Config.Theme.Text
            SuggestionButton.TextXAlignment = Enum.TextXAlignment.Left
            SuggestionButton.ZIndex = 6
            SuggestionButton.Parent = SuggestionsScroll
            
            local DescriptionLabel = Instance.new("TextLabel")
            DescriptionLabel.Name = "Description"
            DescriptionLabel.Size = UDim2.new(0.6, 0, 1, 0)
            DescriptionLabel.Position = UDim2.new(0.4, 0, 0, 0)
            DescriptionLabel.BackgroundTransparency = 1
            DescriptionLabel.Text = cmd.Description or ""
            DescriptionLabel.Font = Enum.Font.Gotham
            DescriptionLabel.TextSize = 12
            DescriptionLabel.TextColor3 = AdminSuite.Config.Theme.TextDark
            DescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
            DescriptionLabel.TextTruncate = Enum.TextTruncate.AtEnd
            DescriptionLabel.ZIndex = 6
            DescriptionLabel.Parent = SuggestionButton
            
            -- Padding
            local ButtonPadding = Instance.new("UIPadding")
            ButtonPadding.PaddingLeft = UDim.new(0, 10)
            ButtonPadding.Parent = SuggestionButton
            
            -- Hover effect
            SuggestionButton.MouseEnter:Connect(function()
                SuggestionButton.BackgroundTransparency = 0.8
                SuggestionButton.BackgroundColor3 = AdminSuite.Config.Theme.Accent
            end)
            
            SuggestionButton.MouseLeave:Connect(function()
                if SuggestionIndex ~= i then
                    SuggestionButton.BackgroundTransparency = 1
                end
            end)
            
            -- Click handler
            SuggestionButton.MouseButton1Click:Connect(function()
                CommandInput.Text = cmd.Name
                CommandInput:CaptureFocus()
                SuggestionsFrame.Visible = false
            end)
        end
        
        -- Show suggestions
        SuggestionIndex = 0
        SuggestionsFrame.Size = UDim2.new(1, 0, 0, math.min(#matches * 30, 200))
        SuggestionsScroll.CanvasSize = UDim2.new(0, 0, 0, #matches * 30)
        SuggestionsFrame.Visible = true
    end
    
    function self:ExecuteCommand(command)
        -- Extract command and arguments
        local args = {}
        for arg in command:gmatch("%S+") do
            table.insert(args, arg)
        end
        
        local cmdName = table.remove(args, 1)
        
        -- Find matching command
        for _, cmd in pairs(AdminSuite.Commands) do
            if cmd.Name:lower() == cmdName:lower() then
                -- Add to analytics
                AdminSuite.Analytics.CommandUsage[cmd.Name] = (AdminSuite.Analytics.CommandUsage[cmd.Name] or 0) + 1
                
                -- Execute command
                local success, result = pcall(function()
                    return cmd.Execute(unpack(args))
                end)
                
                if not success then
                    -- Show error
                    self:ShowNotification("Error", "Failed to execute command: " .. result, "error")
                elseif result then
                    -- Show result notification if command returned a message
                    self:ShowNotification("Command", result, "info")
                end
                
                return
            end
        end
        
        -- Command not found
        self:ShowNotification("Error", "Command not found: " .. cmdName, "error")
    end
    
    -- Method to show notification
    function self:ShowNotification(title, message, type)
        local NotifFrame = Instance.new("Frame")
        NotifFrame.Name = "Notification"
        NotifFrame.Size = UDim2.new(0, 300, 0, 80)
        NotifFrame.Position = UDim2.new(1, 20, 0.8, 0)
        NotifFrame.BackgroundColor3 = AdminSuite.Config.Theme.Secondary
        NotifFrame.BorderSizePixel = 0
        NotifFrame.AnchorPoint = Vector2.new(1, 0.8)
        NotifFrame.Parent = ScreenGui
        
        local NotifCorner = Instance.new("UICorner")
        NotifCorner.CornerRadius = UDim.new(0, 8)
        NotifCorner.Parent = NotifFrame
        
        local NotifTitle = Instance.new("TextLabel")
        NotifTitle.Name = "Title"
        NotifTitle.Size = UDim2.new(1, -20, 0, 30)
        NotifTitle.Position = UDim2.new(0, 10, 0, 5)
        NotifTitle.BackgroundTransparency = 1
        NotifTitle.Text = title
        NotifTitle.Font = Enum.Font.GothamBold
        NotifTitle.TextSize = 16
        NotifTitle.TextColor3 = AdminSuite.Config.Theme.Text
        NotifTitle.TextXAlignment = Enum.TextXAlignment.Left
        NotifTitle.Parent = NotifFrame
        
        local NotifMessage = Instance.new("TextLabel")
        NotifMessage.Name = "Message"
        NotifMessage.Size = UDim2.new(1, -20, 0, 40)
        NotifMessage.Position = UDim2.new(0, 10, 0, 35)
        NotifMessage.BackgroundTransparency = 1
        NotifMessage.Text = message
        NotifMessage.Font = Enum.Font.Gotham
        NotifMessage.TextSize = 14
        NotifMessage.TextColor3 = AdminSuite.Config.Theme.TextDark
        NotifMessage.TextXAlignment = Enum.TextXAlignment.Left
        NotifMessage.TextWrapped = true
        NotifMessage.Parent = NotifFrame
        
        -- Color based on type
        if type == "error" then
            local ColorBar = Instance.new("Frame")
            ColorBar.Name = "ColorBar"
            ColorBar.Size = UDim2.new(0, 5, 1, 0)
            ColorBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            ColorBar.Parent = NotifFrame
            
            local BarCorner = Instance.new("UICorner")
            BarCorner.CornerRadius = UDim.new(0, 8)
            BarCorner.Parent = ColorBar
        elseif type == "success" then
            local ColorBar = Instance.new("Frame")
            ColorBar.Name = "ColorBar"
            ColorBar.Size = UDim2.new(0, 5, 1, 0)
            ColorBar.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
            ColorBar.Parent = NotifFrame
            
            local BarCorner = Instance.new("UICorner")
            BarCorner.CornerRadius = UDim.new(0, 8)
            BarCorner.Parent = ColorBar
        elseif type == "info" then
            local ColorBar = Instance.new("Frame")
            ColorBar.Name = "ColorBar"
            ColorBar.Size = UDim2.new(0, 5, 1, 0)
            ColorBar.BackgroundColor3 = AdminSuite.Config.Theme.Accent
            ColorBar.Parent = NotifFrame
            
            local BarCorner = Instance.new("UICorner")
            BarCorner.CornerRadius = UDim.new(0, 8)
            BarCorner.Parent = ColorBar
        end
        
        -- Animation
        CreateTween(NotifFrame, {Position = UDim2.new(1, -20, 0.8, 0)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
        
        -- Auto close
        task.delay(5, function()
            CreateTween(NotifFrame, {Position = UDim2.new(1, 320, 0.8, 0)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In):Play()
            task.delay(0.3, function()
                NotifFrame:Destroy()
            end)
        end)
    end
    
    -- Setup input handling for toggling UI
    local function setupInputHandling()
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == Enum.KeyCode.Quote then
                -- Toggle main menu
                MenuVisible = not MenuVisible
                
                if MenuVisible then
                    MainContainer.Position = UDim2.new(-0.5, 0, 0.5, -200)
                    MainContainer.Visible = true
                    local tween = CreateTween(MainContainer, {Position = UDim2.new(0.5, -300, 0.5, -200)}, 0.3)
                    tween:Play()
                else
                    local tween = CreateTween(MainContainer, {Position = UDim2.new(-0.5, 0, 0.5, -200)}, 0.3)
                    tween:Play()
                    tween.Completed:Connect(function()
                        MainContainer.Visible = false
                    end)
                end
            elseif input.KeyCode == Enum.KeyCode.Semicolon then
                -- Toggle command bar
                CommandBarVisible = not CommandBarVisible
                
                if CommandBarVisible then
                    CommandBarFrame.Position = UDim2.new(0.5, 0, 0.7, 0)
                    CommandBarFrame.Visible = true
                    local tween = CreateTween(CommandBarFrame, {Position = AdminSuite.Config.CommandBarPosition}, 0.3)
                    tween:Play()
                    task.delay(0.1, function()
                        CommandInput:CaptureFocus()
                    end)
                else
                    SuggestionsFrame.Visible = false
                    local tween = CreateTween(CommandBarFrame, {Position = UDim2.new(0.5, 0, 0.7, 0)}, 0.3)
                    tween:Play()
                    tween.Completed:Connect(function()
                        CommandBarFrame.Visible = false
                    end)
                end
            end
        end)
        
        -- Input handling for command bar
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not CommandInput:IsFocused() then return end
            
            if input.KeyCode == Enum.KeyCode.Up then
                -- Navigate history
                if #CommandHistory > 0 then
                    HistoryIndex = math.min(HistoryIndex + 1, #CommandHistory)
                    CommandInput.Text = CommandHistory[HistoryIndex]
                    CommandInput.CursorPosition = #CommandInput.Text + 1
                end
            elseif input.KeyCode == Enum.KeyCode.Down then
                -- Navigate history
                if HistoryIndex > 1 then
                    HistoryIndex = HistoryIndex - 1
                    CommandInput.Text = CommandHistory[HistoryIndex]
                    CommandInput.CursorPosition = #CommandInput.Text + 1
                elseif HistoryIndex == 1 then
                    HistoryIndex = 0
                    CommandInput.Text = ""
                end
            elseif input.KeyCode == Enum.KeyCode.Tab then
                -- Tab completion
                if SuggestionsFrame.Visible and #CommandSuggestions > 0 then
                    if SuggestionIndex == 0 then
                        SuggestionIndex = 1
                    else
                        SuggestionIndex = (SuggestionIndex % #CommandSuggestions) + 1
                    end
                    
                    -- Update visuals
                    for i, child in ipairs(SuggestionsScroll:GetChildren()) do
                        if child:IsA("TextButton") then
                            if i == SuggestionIndex then
                                child.BackgroundTransparency = 0.8
                                child.BackgroundColor3 = AdminSuite.Config.Theme.Accent
                            else
                                child.BackgroundTransparency = 1
                            end
                        end
                    end
                    
                    -- Apply suggestion
                    CommandInput.Text = CommandSuggestions[SuggestionIndex].Name
                    CommandInput.CursorPosition = #CommandInput.Text + 1
                end
            end
        end)
    end
    
    -- Initialize
    setupInputHandling()
    
    -- Return interface
    return {
        AddTab = function(name, icon, order)
            return self:AddTab(name, icon, order)
        end,
        ShowNotification = function(title, message, type)
            self:ShowNotification(title, message, type)
        end,
        UpdateSuggestions = function(input)
            self:UpdateSuggestions(input)
        end,
        ExecuteCommand = function(command)
            self:ExecuteCommand(command)
        end,
        SetVisible = function(visible)
            MenuVisible = visible
            MainContainer.Visible = visible
        end,
        IsVisible = function()
            return MenuVisible
        end,
        ToggleCommandBar = function(visible)
            CommandBarVisible = visible ~= nil and visible or not CommandBarVisible
            
            if CommandBarVisible then
                CommandBarFrame.Position = UDim2.new(0.5, 0, 0.7, 0)
                CommandBarFrame.Visible = true
                local tween = CreateTween(CommandBarFrame, {Position = AdminSuite.Config.CommandBarPosition}, 0.3)
                tween:Play()
                task.delay(0.1, function()
                    CommandInput:CaptureFocus()
                end)
            else
                SuggestionsFrame.Visible = false
                local tween = CreateTween(CommandBarFrame, {Position = UDim2.new(0.5, 0, 0.7, 0)}, 0.3)
                tween:Play()
                tween.Completed:Connect(function()
                    CommandBarFrame.Visible = false
                end)
            end
        end
    }
end

-- Main admin functionality

-- Initialize system
local gui = GuiLibrary.New()

-- Create main tabs
local mainTab = gui.AddTab("Main", nil, 1)
local playersTab = gui.AddTab("Players", nil, 2)
local visualsTab = gui.AddTab("Visuals", nil, 3)
local toolsTab = gui.AddTab("Tools", nil, 4)
local settingsTab = gui.AddTab("Settings", nil, 5)

-- Main tab sections
local mainSection = mainTab.AddSection("Main Controls", false)
local statusSection = mainTab.AddSection("Status", true)

-- Players tab sections
local playerListSection = playersTab.AddSection("Player List", false)
local playerActionSection = playersTab.AddSection("Player Actions", true)
local playerInfoSection = playersTab.AddSection("Player Info", true)

-- Visuals tab sections
local espSection = visualsTab.AddSection("ESP Settings", false)
local interfaceSection = visualsTab.AddSection("Interface", true)
local worldSection = visualsTab.AddSection("World", true)

-- Tools tab sections
local utilitySection = toolsTab.AddSection("Utilities", false)
local miscToolsSection = toolsTab.AddSection("Misc Tools", true)

-- Settings tab sections
local configSection = settingsTab.AddSection("Configuration", false)
local themeSection = settingsTab.AddSection("Theme", true)
local aboutSection = settingsTab.AddSection("About", true)

-- Add main features
mainSection.AddButton("Refresh Admin", function()
    gui.ShowNotification("System", "Refreshing admin system...", "info")
    
    -- Simulate refreshing
    task.delay(1, function()
        gui.ShowNotification("System", "Admin system refreshed successfully!", "success")
    end)
end)

local flyEnabled = mainSection.AddToggle("Flight Mode", false, function(enabled)
    AdminSuite.Internal.FireEvent("onFlightToggle", enabled)
    gui.ShowNotification("Flight", enabled and "Flight mode enabled" or "Flight mode disabled", enabled and "success" or "info")
end)

local walkspeedValue = mainSection.AddSlider("Walkspeed", 16, 500, 16, function(value)
    AdminSuite.Internal.FireEvent("onWalkspeedChange", value)
end)

local jumpPowerValue = mainSection.AddSlider("Jump Power", 50, 500, 50, function(value)
    AdminSuite.Internal.FireEvent("onJumpPowerChange", value)
end)

-- Status display
local statusLabel = statusSection.AddLabel("Status: Ready")
local pingLabel = statusSection.AddLabel("Ping: Calculating...")
local fpsLabel = statusSection.AddLabel("FPS: Calculating...")

-- FPS counter
local lastUpdate = tick()
local frameCount = 0

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    
    local now = tick()
    local elapsed = now - lastUpdate
    
    if elapsed >= 1 then
        local fps = math.floor(frameCount / elapsed)
        fpsLabel.SetText("FPS: " .. fps)
        
        -- Update ping as well
        local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
        pingLabel.SetText("Ping: " .. ping .. "ms")
        
        lastUpdate = now
        frameCount = 0
    end
end)

-- Command System
AdminSuite.Commands = {}

-- Add command function
local function AddCommand(name, aliases, description, usage, execute)
    local command = {
        Name = name,
        Aliases = aliases or {},
        Description = description,
        Usage = usage,
        Execute = execute
    }
    
    table.insert(AdminSuite.Commands, command)
    
    for _, alias in ipairs(aliases or {}) do
        local aliasCommand = DeepCopy(command)
        aliasCommand.Name = alias
        aliasCommand.IsAlias = true
        aliasCommand.OriginalName = name
        table.insert(AdminSuite.Commands, aliasCommand)
    end
    
    return command
end

-- Build Player List
local playerButtons = {}
local selectedPlayer = nil

local function UpdatePlayerList()
    -- Clear existing buttons
    for _, button in pairs(playerButtons) do
        button:Destroy()
    end
    playerButtons = {}
    
    -- Add players
    for _, player in ipairs(Players:GetPlayers()) do
        local playerButton = Instance.new("TextButton")
        playerButton.Size = UDim2.new(1, 0, 0, 40)
        playerButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        playerButton.BackgroundTransparency = 0.7
        playerButton.Text = ""
        playerButton.Parent = playerListSection.Instance
        
        local playerName = Instance.new("TextLabel")
        playerName.Size = UDim2.new(1, -80, 1, 0)
        playerName.Position = UDim2.new(0, 10, 0, 0)
        playerName.BackgroundTransparency = 1
        playerName.Text = FormatPlayerName(player)
        playerName.Font = Enum.Font.Gotham
        playerName.TextSize = 14
        playerName.TextColor3 = AdminSuite.Config.Theme.Text
        playerName.TextXAlignment = Enum.TextXAlignment.Left
        playerName.TextTruncate = Enum.TextTruncate.AtEnd
        playerName.Parent = playerButton
        
        -- Select button
        local selectButton = Instance.new("TextButton")
        selectButton.Size = UDim2.new(0, 60, 0, 30)
        selectButton.Position = UDim2.new(1, -70, 0.5, 0)
        selectButton.AnchorPoint = Vector2.new(0, 0.5)
        selectButton.BackgroundColor3 = AdminSuite.Config.Theme.Accent
        selectButton.BackgroundTransparency = 0.5
        selectButton.Text = "Select"
        selectButton.Font = Enum.Font.Gotham
        selectButton.TextSize = 12
        selectButton.TextColor3 = Color3.new(1, 1, 1)
        selectButton.Parent = playerButton
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = selectButton
        
        local buttonCorner2 = Instance.new("UICorner")
        buttonCorner2.CornerRadius = UDim.new(0, 6)
        buttonCorner2.Parent = playerButton
        
        -- Click handlers
        selectButton.MouseButton1Click:Connect(function()
            selectedPlayer = player
            gui.ShowNotification("Player", "Selected " .. player.Name, "info")
            
            -- Update player info
            UpdatePlayerInfo(player)
        end)
        
        table.insert(playerButtons, playerButton)
    end
end

-- Update player info panel
function UpdatePlayerInfo(player)
    -- Clear existing info
    for _, child in pairs(playerInfoSection.Instance:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    if not player or not player:IsA("Player") then
        playerInfoSection.AddLabel("No player selected")
        return
    end
    
    -- Add player info
    playerInfoSection.AddLabel("Name: " .. player.Name)
    playerInfoSection.AddLabel("Display Name: " .. player.DisplayName)
    playerInfoSection.AddLabel("UserId: " .. player.UserId)
    playerInfoSection.AddLabel("Account Age: " .. player.AccountAge .. " days")
    
    local character = player.Character
    if character then
        playerInfoSection.AddLabel("Health: " .. math.floor((character:FindFirstChild("Humanoid") and character.Humanoid.Health or 0)) .. "/" .. 
                                   math.floor((character:FindFirstChild("Humanoid") and character.Humanoid.MaxHealth or 0)))
        
        -- Position
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local pos = rootPart.Position
            playerInfoSection.AddLabel("Position: " .. math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. ", " .. math.floor(pos.Z))
        end
    else
        playerInfoSection.AddLabel("Character: Not loaded")
    end
    
    -- Get device info
    pcall(function()
        local success, cap = ReplicatedStorage:RequestDeviceCameraOrientationCapability()
        if success then
            playerInfoSection.AddLabel("Device: " .. (cap == Enum.DeviceCameraOrientationMode.LandscapeRight and "Mobile" or "PC/Console"))
        else
            playerInfoSection.AddLabel("Device: Unknown")
        end
    end)
    
    -- Team info
    playerInfoSection.AddLabel("Team: " .. (player.Team and player.Team.Name or "None"))
}

-- Initialize player list
UpdatePlayerList()

-- Update player list when players join/leave
Players.PlayerAdded:Connect(UpdatePlayerList)
Players.PlayerRemoving:Connect(UpdatePlayerList)

-- Player actions
playerActionSection.AddButton("Teleport To", function()
    if selectedPlayer and selectedPlayer.Character then
        local myCharacter = LocalPlayer.Character
        if myCharacter then
            local targetRoot = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
            
            if targetRoot and myRoot then
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                gui.ShowNotification("Teleport", "Teleported to " .. selectedPlayer.Name, "success")
            else
                gui.ShowNotification("Error", "Could not teleport - missing root parts", "error")
            end
        else
            gui.ShowNotification("Error", "Your character is not loaded", "error")
        end
    else
        gui.ShowNotification("Error", "No player selected or player's character not loaded", "error")
    end
end)

playerActionSection.AddButton("Spectate", function()
    if selectedPlayer then
        AdminSuite.Internal.FireEvent("onSpectateToggle", selectedPlayer)
        gui.ShowNotification("Spectate", "Now spectating " .. selectedPlayer.Name, "info")
    else
        gui.ShowNotification("Error", "No player selected", "error")
    end
end)

playerActionSection.AddButton("Stop Spectating", function()
    AdminSuite.Internal.FireEvent("onSpectateToggle", nil)
    gui.ShowNotification("Spectate", "Stopped spectating", "info")
end)

playerActionSection.AddButton("Copy UserId", function()
    if selectedPlayer then
        if setclipboard then
            setclipboard(tostring(selectedPlayer.UserId))
            gui.ShowNotification("Copied", "UserId copied to clipboard", "success")
        else
            gui.ShowNotification("Error", "Clipboard function not available", "error")
        end
    else
        gui.ShowNotification("Error", "No player selected", "error")
    end
end)

-- ESP Settings
local espEnabled = espSection.AddToggle("Enable ESP", false, function(enabled)
    AdminSuite.Internal.FireEvent("onESPToggle", enabled)
    gui.ShowNotification("ESP", enabled and "ESP enabled" or "ESP disabled", enabled and "success" or "info")
end)

local boxEspEnabled = espSection.AddToggle("Box ESP", false, function(enabled)
    AdminSuite.Internal.FireEvent("onBoxESPToggle", enabled)
end)

local nameEspEnabled = espSection.AddToggle("Name ESP", false, function(enabled)
    AdminSuite.Internal.FireEvent("onNameESPToggle", enabled)
end)

local healthEspEnabled = espSection.AddToggle("Health ESP", false, function(enabled)
    AdminSuite.Internal.FireEvent("onHealthESPToggle", enabled)
end)

local distanceEspEnabled = espSection.AddToggle("Distance ESP", false, function(enabled)
    AdminSuite.Internal.FireEvent("onDistanceESPToggle", enabled)
end)

local espDistance = espSection.AddSlider("ESP Max Distance", 100, 5000, 2000, function(value)
    AdminSuite.Internal.FireEvent("onESPDistanceChange", value)
end)

local espTeamColor = espSection.AddToggle("Use Team Colors", true, function(enabled)
    AdminSuite.Internal.FireEvent("onESPTeamColorToggle", enabled)
end)

-- World visuals
local fullBrightEnabled = worldSection.AddToggle("Full Bright", false, function(enabled)
    AdminSuite.Internal.FireEvent("onFullBrightToggle", enabled)
    gui.ShowNotification("Lighting", enabled and "Full brightness enabled" or "Full brightness disabled", enabled and "success" or "info")
end)

local noFogEnabled = worldSection.AddToggle("No Fog", false, function(enabled)
    AdminSuite.Internal.FireEvent("onNoFogToggle", enabled)
end)

-- Utility tools
utilitySection.AddButton("Server Info", function()
    local stats = {}
    stats.Players = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
    stats.PlaceId = game.PlaceId
    stats.JobId = game.JobId
    stats.PrivateServer = game.PrivateServerId ~= ""
    
    local message = "Server Info:\n"
    for k, v in pairs(stats) do
        message = message .. "• " .. k .. ": " .. tostring(v) .. "\n"
    end
    
    gui.ShowNotification("Server Info", message, "info")
end)

utilitySection.AddButton("Copy Join Script", function()
    if setclipboard then
        local script = [[
        game:GetService("TeleportService"):TeleportToPlaceInstance(]] .. game.PlaceId .. [[, "]] .. game.JobId .. [[")
        ]]
        setclipboard(script)
        gui.ShowNotification("Copied", "Join script copied to clipboard", "success")
    else
        gui.ShowNotification("Error", "Clipboard function not available", "error")
    end
end)

-- Miscellaneous Tools
miscToolsSection.AddButton("Rejoin Server", function()
    local ts = game:GetService("TeleportService")
    ts:Teleport(game.PlaceId, LocalPlayer)
    gui.ShowNotification("Teleport", "Rejoining server...", "info")
end)

miscToolsSection.AddButton("Server Hop", function()
    gui.ShowNotification("Server Hop", "Looking for a new server...", "info")
    
    -- Simulate server hop (limited by client capabilities)
    local ts = game:GetService("TeleportService")
    ts:Teleport(game.PlaceId, LocalPlayer)
end)

-- Config settings
local autoSaveToggle = configSection.AddToggle("Auto Save Settings", AdminSuite.Config.AutoSave, function(enabled)
    AdminSuite.Config.AutoSave = enabled
    AdminSuite.Internal.SaveConfig()
})

local cmdPrefixBox = configSection.AddTextBox("Command Prefix", AdminSuite.Config.Prefix, ";", function(text)
    if #text == 1 then
        AdminSuite.Config.Prefix = text
        CommandPrefix.Text = text
        AdminSuite.Internal.SaveConfig()
    else
        gui.ShowNotification("Error", "Prefix must be a single character", "error")
    end
end)

local toggleKeyBox = configSection.AddTextBox("Toggle Key", AdminSuite.Config.ToggleKey, "'", function(text)
    if #text == 1 then
        AdminSuite.Config.ToggleKey = text
        AdminSuite.Internal.SaveConfig()
    else
        gui.ShowNotification("Error", "Toggle key must be a single character", "error")
    end
end)

configSection.AddButton("Save Settings", function()
    AdminSuite.Internal.SaveConfig()
    gui.ShowNotification("Settings", "Configuration saved successfully", "success")
end)

configSection.AddButton("Reset Settings", function()
    -- Reset to defaults
    AdminSuite.Config = {
        Prefix = ";",
        ToggleKey = "'",
        Theme = {
            Primary = Color3.fromRGB(40, 40, 60),
            Secondary = Color3.fromRGB(60, 60, 80),
            Accent = Color3.fromRGB(100, 100, 255),
            Text = Color3.fromRGB(255, 255, 255),
            TextDark = Color3.fromRGB(200, 200, 200)
        },
        CommandBarPosition = UDim2.new(0.5, 0, 0.8, 0),
        UIScale = 1,
        CommandsPerPage = 10,
        AutoSave = true
    }
    
    AdminSuite.Internal.SaveConfig()
    gui.ShowNotification("Settings", "Settings reset to defaults", "info")
    
    -- Update UI elements
    autoSaveToggle.SetValue(AdminSuite.Config.AutoSave)
    cmdPrefixBox.SetText(AdminSuite.Config.Prefix)
    toggleKeyBox.SetText(AdminSuite.Config.ToggleKey)
end)

-- Theme settings
local primaryColorPicker = themeSection.AddColorPicker("Primary Color", AdminSuite.Config.Theme.Primary, function(color)
    AdminSuite.Config.Theme.Primary = color
    AdminSuite.Internal.SaveConfig()
    gui.ShowNotification("Theme", "Primary color updated. Restart admin to apply changes.", "info")
end)

local secondaryColorPicker = themeSection.AddColorPicker("Secondary Color", AdminSuite.Config.Theme.Secondary, function(color)
    AdminSuite.Config.Theme.Secondary = color
    AdminSuite.Internal.SaveConfig()
    gui.ShowNotification("Theme", "Secondary color updated. Restart admin to apply changes.", "info")
end)

local accentColorPicker = themeSection.AddColorPicker("Accent Color", AdminSuite.Config.Theme.Accent, function(color)
    AdminSuite.Config.Theme.Accent = color
    AdminSuite.Internal.SaveConfig()
    gui.ShowNotification("Theme", "Accent color updated. Restart admin to apply changes.", "info")
end)

-- About section
aboutSection.AddLabel("XVI Admin Suite")
aboutSection.AddLabel("Version: 1.0.0")
aboutSection.AddLabel("Created for client-side admin functionality")
aboutSection.AddLabel("© 2023 XVI Admin Suite")

-- Define commands
AddCommand("help", {"cmds", "commands"}, "Shows command list or info about a specific command", "help [command]", function(cmdName)
    if cmdName then
        -- Find command
        for _, cmd in pairs(AdminSuite.Commands) do
            if cmd.Name:lower() == cmdName:lower() then
                return "Command: " .. cmd.Name .. "\nDescription: " .. (cmd.Description or "No description") .. 
                       "\nUsage: " .. AdminSuite.Config.Prefix .. (cmd.Usage or cmd.Name)
            end
        end
        return "Command not found: " .. cmdName
    else
        -- List all commands
        local message = "Available Commands:"
        local categories = {}
        
        for _, cmd in pairs(AdminSuite.Commands) do
            if not cmd.IsAlias then
                local category = cmd.Category or "Misc"
                categories[category] = categories[category] or {}
                table.insert(categories[category], cmd.Name)
            end
        end
        
        for category, cmds in pairs(categories) do
            message = message .. "\n\n" .. category .. ":\n"
            table.sort(cmds)
            message = message .. table.concat(cmds, ", ")
        end
        
        return message
    end
end)

AddCommand("speed", {"ws", "walkspeed"}, "Sets your walkspeed", "speed <value>", function(speed)
    if not speed then
        return "Current walkspeed: " .. (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and 
                                       LocalPlayer.Character.Humanoid.WalkSpeed or "N/A")
    end
    
    local numSpeed = tonumber(speed)
    if not numSpeed then
        return "Invalid speed value. Please enter a number."
    end
    
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = numSpeed
        walkspeedValue.SetValue(numSpeed)
        return "Set walkspeed to " .. numSpeed
    else
        return "Character or Humanoid not found"
    end
end)

AddCommand("jump", {"jp", "jumppower"}, "Sets your jump power", "jump <value>", function(power)
    if not power then
        return "Current jump power: " .. (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and 
                                       LocalPlayer.Character.Humanoid.JumpPower or "N/A")
    end
    
    local numPower = tonumber(power)
    if not numPower then
        return "Invalid jump power value. Please enter a number."
    end
    
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.JumpPower = numPower
        jumpPowerValue.SetValue(numPower)
        return "Set jump power to " .. numPower
    else
        return "Character or Humanoid not found"
    end
end)

AddCommand("fly", {}, "Toggles flight mode", "fly [speed]", function(speed)
    local isFlying = flyEnabled.GetValue()
    flyEnabled.Toggle()
    
    if speed then
        local numSpeed = tonumber(speed)
        if numSpeed then
            AdminSuite.Internal.FireEvent("onFlightSpeedChange", numSpeed)
        end
    end
    
    return isFlying and "Flight disabled" or "Flight enabled"
end)

AddCommand("noclip", {}, "Toggles noclip mode", "noclip", function()
    AdminSuite.Internal.FireEvent("onNoclipToggle")
    return "Toggled noclip"
end)

AddCommand("esp", {}, "Toggles ESP features", "esp [feature] [on/off]", function(feature, state)
    if not feature then
        -- Toggle main ESP
        espEnabled.Toggle()
        return "Toggled ESP " .. (espEnabled.GetValue() and "on" or "off")
    end
    
    feature = feature:lower()
    local toggle = state == "on" or state == "true" or state == "1"
    
    if feature == "box" or feature == "boxes" then
        boxEspEnabled.SetValue(state and toggle or not boxEspEnabled.GetValue())
        return "Toggled Box ESP " .. (boxEspEnabled.GetValue() and "on" or "off")
    elseif feature == "name" or feature == "names" then
        nameEspEnabled.SetValue(state and toggle or not nameEspEnabled.GetValue())
        return "Toggled Name ESP " .. (nameEspEnabled.GetValue() and "on" or "off")
    elseif feature == "health" then
        healthEspEnabled.SetValue(state and toggle or not healthEspEnabled.GetValue())
        return "Toggled Health ESP " .. (healthEspEnabled.GetValue() and "on" or "off")
    elseif feature == "distance" then
        distanceEspEnabled.SetValue(state and toggle or not distanceEspEnabled.GetValue())
        return "Toggled Distance ESP " .. (distanceEspEnabled.GetValue() and "on" or "off")
    elseif feature == "team" or feature == "teamcolor" then
        espTeamColor.SetValue(state and toggle or not espTeamColor.GetValue())
        return "Toggled Team Color ESP " .. (espTeamColor.GetValue() and "on" or "off")
    elseif feature == "distance" and tonumber(state) then
        espDistance.SetValue(tonumber(state))
        return "Set ESP max distance to " .. tonumber(state)
    else
        return "Unknown ESP feature: " .. feature
    end
end)

AddCommand("goto", {"to"}, "Teleport to a player", "goto <player>", function(playerName)
    if not playerName then
        return "Please specify a player name"
    end
    
    local target = FindPlayer(playerName)
    if not target then
        return "Player not found: " .. playerName
    end
    
    local myCharacter = LocalPlayer.Character
    local targetCharacter = target.Character
    
    if not myCharacter or not targetCharacter then
        return "Character not loaded"
    end
    
    local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    
    if not myRoot or not targetRoot then
        return "HumanoidRootPart not found"
    end
    
    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
    return "Teleported to " .. target.Name
end)

AddCommand("bring", {}, "Simulates bringing a player to you (visual only)", "bring <player>", function(playerName)
    if not playerName then
        return "Please specify a player name"
    end
    
    local target = FindPlayer(playerName)
    if not target then
        return "Player not found: " .. playerName
    end
    
    -- This is client-side only, so we can only manipulate local instances
    AdminSuite.Internal.FireEvent("onVisualizeBring", target)
    return "Visualizing bring for " .. target.Name
end)

AddCommand("spectate", {"spec"}, "Spectate a player", "spectate <player>", function(playerName)
    if not playerName or playerName == "off" or playerName == "me" then
        AdminSuite.Internal.FireEvent("onSpectateToggle", nil)
        return "Stopped spectating"
    end
    
    local target = FindPlayer(playerName)
    if not target then
        return "Player not found: " .. playerName
    end
    
    AdminSuite.Internal.FireEvent("onSpectateToggle", target)
    return "Now spectating " .. target.Name
end)

AddCommand("rejoin", {"rj"}, "Rejoin the current server", "rejoin", function()
    local ts = game:GetService("TeleportService")
    ts:Teleport(game.PlaceId, LocalPlayer)
    return "Rejoining server..."
end)

AddCommand("serverhop", {"shop"}, "Join a different server", "serverhop", function()
    -- Simulate server hop (limited by client capabilities)
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    return "Looking for a new server..."
end)

AddCommand("info", {"playerinfo", "pi"}, "Shows information about a player", "info <player>", function(playerName)
    if not playerName then
        return "Please specify a player name"
    end
    
    local target = FindPlayer(playerName)
    if not target then
        return "Player not found: " .. playerName
    end
    
    -- Generate info
    local info = "Player: " .. target.Name .. " (@" .. target.DisplayName .. ")\n"
    info = info .. "UserId: " .. target.UserId .. "\n"
    info = info .. "Account Age: " .. target.AccountAge .. " days\n"
    
    if target.Character then
        local humanoid = target.Character:FindFirstChild("Humanoid")
        if humanoid then
            info = info .. "Health: " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth) .. "\n"
        end
        
        local rootPart = target.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local pos = rootPart.Position
            info = info .. "Position: " .. math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. ", " .. math.floor(pos.Z) .. "\n"
            
            -- Distance
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local myPos = LocalPlayer.Character.HumanoidRootPart.Position
                local distance = (myPos - pos).Magnitude
                info = info .. "Distance: " .. math.floor(distance) .. " studs\n"
            end
        end
    else
        info = info .. "Character: Not loaded\n"
    end
    
    info = info .. "Team: " .. (target.Team and target.Team.Name or "None") .. "\n"
    
    -- Get device info
    pcall(function()
        local success, cap = game:GetService("ReplicatedStorage"):RequestDeviceCameraOrientationCapability()
        if success then
            info = info .. "Device: " .. (cap == Enum.DeviceCameraOrientationMode.LandscapeRight and "Mobile" or "PC/Console") .. "\n"
        end
    end)
    
    return info
end)

AddCommand("fps", {"showfps"}, "Toggles FPS counter", "fps", function()
    AdminSuite.Internal.FireEvent("onFPSCounterToggle")
    return "Toggled FPS counter"
end)

AddCommand("ping", {"showping"}, "Toggles ping counter", "ping", function()
    AdminSuite.Internal.FireEvent("onPingCounterToggle")
    return "Toggled ping counter"
end)

AddCommand("fullbright", {"fb", "brightness"}, "Toggles full brightness", "fullbright", function()
    fullBrightEnabled.Toggle()
    return "Toggled full brightness " .. (fullBrightEnabled.GetValue() and "on" or "off")
end)

AddCommand("nofog", {}, "Toggles fog", "nofog", function()
    noFogEnabled.Toggle()
    return "Toggled fog " .. (noFogEnabled.GetValue() and "off" or "on")
end)

AddCommand("theme", {}, "Changes UI theme color", "theme <primary/secondary/accent> <r> <g> <b>", function(element, r, g, b)
    if not element or not r or not g or not b then
        return "Usage: theme <primary/secondary/accent> <r> <g> <b>"
    end
    
    local nr, ng, nb = tonumber(r), tonumber(g), tonumber(b)
    if not nr or not ng or not nb then
        return "RGB values must be numbers between 0-255"
    end
    
    nr = math.clamp(nr, 0, 255)
    ng = math.clamp(ng, 0, 255)
    nb = math.clamp(nb, 0, 255)
    
    local color = Color3.fromRGB(nr, ng, nb)
    
    if element:lower() == "primary" then
        AdminSuite.Config.Theme.Primary = color
        primaryColorPicker.SetColor(color)
    elseif element:lower() == "secondary" then
        AdminSuite.Config.Theme.Secondary = color
        secondaryColorPicker.SetColor(color)
    elseif element:lower() == "accent" then
        AdminSuite.Config.Theme.Accent = color
        accentColorPicker.SetColor(color)
    else
        return "Invalid element. Use primary, secondary, or accent"
    end
    
    AdminSuite.Internal.SaveConfig()
    return "Set " .. element .. " color to RGB(" .. nr .. "," .. ng .. "," .. nb .. ")"
end)

AddCommand("prefix", {}, "Changes command prefix", "prefix <character>", function(char)
    if not char or #char ~= 1 then
        return "Prefix must be a single character"
    end
    
    AdminSuite.Config.Prefix = char
    CommandPrefix.Text = char
    cmdPrefixBox.SetText(char)
    AdminSuite.Internal.SaveConfig()
    return "Command prefix changed to '" .. char .. "'"
end)

AddCommand("togglekey", {}, "Changes UI toggle key", "togglekey <character>", function(char)
    if not char or #char ~= 1 then
        return "Toggle key must be a single character"
    end
    
    AdminSuite.Config.ToggleKey = char
    toggleKeyBox.SetText(char)
    AdminSuite.Internal.SaveConfig()
    return "UI toggle key changed to '" .. char .. "'"
end)

AddCommand("reset", {"respawn"}, "Respawns your character", "reset", function()
    if LocalPlayer.Character then
        LocalPlayer.Character:BreakJoints()
        return "Resetting character..."
    else
        return "Character not loaded"
    end
end)

AddCommand("save", {"savesettings"}, "Saves current settings", "save", function()
    AdminSuite.Internal.SaveConfig()
    return "Settings saved successfully"
end)

AddCommand("version", {"ver"}, "Shows admin version", "version", function()
    return "XVI Admin Suite\nVersion: 1.0.0\nRunning on: " .. LocalPlayer.Name .. "'s client"
end)

-- Implement spectate functionality
local spectating = nil
local originalCameraCFrame = nil
local originalCameraSubject = nil

AdminSuite.Internal.ConnectEvent("onSpectateToggle", function(player)
    local camera = workspace.CurrentCamera
    
    if spectating then
        -- Stop spectating
        camera.CameraSubject = originalCameraSubject
        if originalCameraCFrame then
            camera.CFrame = originalCameraCFrame
        end
        spectating = nil
    end
    
    if player then
        -- Start spectating
        originalCameraSubject = camera.CameraSubject
        originalCameraCFrame = camera.CFrame
        
        spectating = player
        
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            camera.CameraSubject = player.Character.Humanoid
        end
    end
end)

-- Implement flight functionality
local flying = false
local flySpeed = 2
local maxFlightSpeed = 20

AdminSuite.Internal.ConnectEvent("onFlightToggle", function(enabled)
    flying = enabled
    
    if not flying then return end
    
    -- Flight implementation
    local startFlight = function()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local hrp = character.HumanoidRootPart
        local velocity = Instance.new("BodyVelocity")
        velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        velocity.Velocity = Vector3.new(0, 0, 0)
        velocity.Name = "XVI_Flight_Velocity"
        velocity.Parent = hrp
        
        local gyro = Instance.new("BodyGyro")
        gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        gyro.D = 100
        gyro.P = 10000
        gyro.Name = "XVI_Flight_Gyro"
        gyro.Parent = hrp
        
        -- Flight Loop
        local flightConnection
        flightConnection = RunService.RenderStepped:Connect(function()
            if not flying then
                flightConnection:Disconnect()
                if velocity and velocity.Parent then velocity:Destroy() end
                if gyro and gyro.Parent then gyro:Destroy() end
                return
            end
            
            if not character or not character.Parent or not hrp or not hrp.Parent then
                flightConnection:Disconnect()
                return
            end
            
            -- Update gyro orientation
            local camera = workspace.CurrentCamera
            gyro.CFrame = camera.CFrame
            
            -- Calculate movement direction
            local movementVector = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                movementVector = movementVector + camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                movementVector = movementVector - camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                movementVector = movementVector - camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                movementVector = movementVector + camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                movementVector = movementVector + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                movementVector = movementVector - Vector3.new(0, 1, 0)
            end
            
            -- Normalize and apply speed
            if movementVector.Magnitude > 0 then
                movementVector = movementVector.Unit * flySpeed
            end
            
            velocity.Velocity = movementVector * 35
        end)
    end
    
    startFlight()
end)

AdminSuite.Internal.ConnectEvent("onFlightSpeedChange", function(speed)
    flySpeed = math.clamp(speed, 1, maxFlightSpeed)
end)

-- Show success notification
gui.ShowNotification("XVI Admin Suite", "Loaded successfully! Press ' to open menu, ; for command bar.", "success")

return AdminSuite
