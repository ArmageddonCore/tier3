--[[
    ui library
    lightweight and modular ui component framework
    version: 1.0.0
]]

local ui_library = {}
local tweening_service = game:GetService("TweenService")
local core_gui = game:GetService("CoreGui")
local user_input_service = game:GetService("UserInputService")
local run_service = game:GetService("RunService")

-- configuration
local config = {
    theme = {
        background = Color3.fromRGB(30, 30, 30),
        foreground = Color3.fromRGB(40, 40, 40),
        accent = Color3.fromRGB(120, 170, 240),
        text = Color3.fromRGB(240, 240, 240),
        text_dark = Color3.fromRGB(180, 180, 180),
        error = Color3.fromRGB(255, 100, 100),
        success = Color3.fromRGB(100, 255, 150),
        warning = Color3.fromRGB(255, 200, 100),
        transparency = 0.1
    },
    animation = {
        duration = 0.2,
        style = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.Out
    },
    corner_radius = UDim.new(0, 6)
}

-- initialize the container for all gui elements
local function setup_container()
    -- check if container already exists
    if core_gui:FindFirstChild("UILibraryContainer") then
        return core_gui:FindFirstChild("UILibraryContainer")
    end
    
    -- create main container
    local container = Instance.new("Folder")
    container.Name = "UILibraryContainer"
    container.Parent = core_gui
    
    return container
end

-- core ui container
ui_library.container = setup_container()

-- create a basic ui element
function ui_library:create_element(class_type, properties)
    local element = Instance.new(class_type)
    
    -- apply properties if provided
    if properties then
        for property, value in pairs(properties) do
            element[property] = value
        end
    end
    
    return element
end

-- add corner to an element
function ui_library:corner(element, radius)
    local corner = self:create_element("UICorner", {
        CornerRadius = radius or config.corner_radius,
        Parent = element
    })
    
    return corner
end

-- add stroke to an element
function ui_library:stroke(element, color, thickness, transparency)
    local stroke = self:create_element("UIStroke", {
        Color = color or config.theme.accent,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        Parent = element
    })
    
    return stroke
end

-- add padding to an element
function ui_library:padding(element, padding)
    local padding_instance = self:create_element("UIPadding", {
        PaddingTop = UDim.new(0, padding or 5),
        PaddingBottom = UDim.new(0, padding or 5),
        PaddingLeft = UDim.new(0, padding or 5),
        PaddingRight = UDim.new(0, padding or 5),
        Parent = element
    })
    
    return padding_instance
end

-- add list layout to an element
function ui_library:list_layout(element, padding, horizontal_alignment, vertical_alignment)
    local list_layout = self:create_element("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, padding or 5),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = horizontal_alignment or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vertical_alignment or Enum.VerticalAlignment.Top,
        Parent = element
    })
    
    -- ensure correct canvas sizing for scrolling frames
    if element:IsA("ScrollingFrame") then
        list_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            element.CanvasSize = UDim2.new(0, 0, 0, list_layout.AbsoluteContentSize.Y + 10)
        end)
    end
    
    return list_layout
end

-- custom scrolling implementation
function ui_library:create_custom_scrolling_frame(parent, size, position)
    -- container frame
    local frame = self:create_element("Frame", {
        Size = size or UDim2.new(1, 0, 1, 0),
        Position = position or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = parent
    })
    
    -- content frame that will be scrolled
    local content = self:create_element("Frame", {
        Size = UDim2.new(1, -10, 1, 0), -- leave space for scrollbar
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = frame
    })
    
    -- scrollbar background
    local scrollbar_bg = self:create_element("Frame", {
        Size = UDim2.new(0, 6, 1, 0),
        Position = UDim2.new(1, -8, 0, 0),
        BackgroundColor3 = config.theme.foreground,
        BorderSizePixel = 0,
        Parent = frame
    })
    
    self:corner(scrollbar_bg, UDim.new(1, 0))
    
    -- scrollbar handle
    local scrollbar = self:create_element("Frame", {
        Size = UDim2.new(1, 0, 0.3, 0), -- initial size, will change based on content
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = config.theme.accent,
        BorderSizePixel = 0,
        Parent = scrollbar_bg
    })
    
    self:corner(scrollbar, UDim.new(1, 0))
    
    -- add list layout to content
    local list_layout = self:list_layout(content, 5)
    
    -- scroll functionality variables
    local total_content_height = 0
    local visible_height = 0
    local scroll_position = 0
    local max_scroll = 0
    local scrolling = false
    
    -- update scroll position
    local function update_scroll()
        -- update content position for scrolling effect
        content.Position = UDim2.new(0, 0, 0, -scroll_position)
        
        -- update scrollbar position based on scroll percentage
        if max_scroll > 0 then
            local scroll_percent = scroll_position / max_scroll
            scrollbar.Position = UDim2.new(0, 0, scroll_percent, 0)
        else
            scrollbar.Position = UDim2.new(0, 0, 0, 0)
        end
    end
    
    -- update scroll information
    local function update_scroll_info()
        total_content_height = list_layout.AbsoluteContentSize.Y
        visible_height = frame.AbsoluteSize.Y
        
        -- calculate max scroll
        max_scroll = math.max(0, total_content_height - visible_height)
        
        -- update scrollbar size based on content/viewport ratio
        local size_ratio = visible_height / total_content_height
        scrollbar.Size = UDim2.new(1, 0, math.min(1, math.max(0.1, size_ratio)), 0)
        
        -- clamp current scroll position to max
        scroll_position = math.min(scroll_position, max_scroll)
        
        -- hide scrollbar if not needed
        scrollbar_bg.Visible = max_scroll > 0
        
        -- update scroll visuals
        update_scroll()
    end
    
    -- mouse wheel scrolling
    frame.MouseWheelForward:Connect(function()
        if max_scroll > 0 then
            scroll_position = math.max(0, scroll_position - 30)
            update_scroll()
        end
    end)
    
    frame.MouseWheelBackward:Connect(function()
        if max_scroll > 0 then
            scroll_position = math.min(max_scroll, scroll_position + 30)
            update_scroll()
        end
    end)
    
    -- scrollbar dragging
    scrollbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            scrolling = true
        end
    end)
    
    scrollbar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            scrolling = false
        end
    end)
    
    user_input_service.InputChanged:Connect(function(input)
        if scrolling and input.UserInputType == Enum.UserInputType.MouseMovement then
            -- calculate new scroll position based on mouse's relative position to scrollbar background
            local mouse_pos = input.Position.Y
            local scroll_bg_pos = scrollbar_bg.AbsolutePosition.Y
            local scroll_bg_size = scrollbar_bg.AbsoluteSize.Y
            
            local relative_pos = (mouse_pos - scroll_bg_pos) / scroll_bg_size
            relative_pos = math.clamp(relative_pos, 0, 1)
            
            scroll_position = relative_pos * max_scroll
            update_scroll()
        end
    end)
    
    -- update when content changes
    list_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update_scroll_info)
    
    -- update when frame size changes
    frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(update_scroll_info)
    
    -- initial update
    task.delay(0.1, update_scroll_info)
    
    -- interface
    return {
        frame = frame,
        content = content,
        add_item = function(item)
            item.Parent = content
            task.delay(0.05, update_scroll_info) -- slight delay to allow rendering
            return item
        end,
        clear = function()
            for _, child in ipairs(content:GetChildren()) do
                if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                    child:Destroy()
                end
            end
            scroll_position = 0
            update_scroll_info()
        end,
        scroll_to_top = function()
            scroll_position = 0
            update_scroll()
        end,
        scroll_to_bottom = function()
            scroll_position = max_scroll
            update_scroll()
        end
    }
end

-- custom dragging implementation
function ui_library:make_draggable(frame, drag_handle)
    local dragging = false
    local drag_start = nil
    local start_pos = nil
    
    -- handle can be the frame itself or a designated drag area
    local handle = drag_handle or frame
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            drag_start = input.Position
            start_pos = frame.Position
        end
    end)
    
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    user_input_service.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - drag_start
            frame.Position = UDim2.new(
                start_pos.X.Scale,
                start_pos.X.Offset + delta.X,
                start_pos.Y.Scale,
                start_pos.Y.Offset + delta.Y
            )
        end
    end)
    
    return {
        set_draggable = function(enabled)
            dragging = false
        end
    }
end

-- create a window frame
function ui_library:create_window(title, size, position)
    -- window frame
    local window_frame = self:create_element("Frame", {
        Name = title or "Window",
        Size = size or UDim2.new(0, 300, 0, 350),
        Position = position or UDim2.new(0.5, -150, 0.5, -175),
        BackgroundColor3 = config.theme.background,
        BorderSizePixel = 0,
        Parent = self.container
    })
    
    self:corner(window_frame)
    self:stroke(window_frame, config.theme.accent)
    
    -- title bar
    local title_bar = self:create_element("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = config.theme.foreground,
        BorderSizePixel = 0,
        Parent = window_frame
    })
    
    self:corner(title_bar)
    
    -- title text
    local title_text = self:create_element("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "Window",
        TextColor3 = config.theme.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        Parent = title_bar
    })
    
    -- close button
    local close_button = self:create_element("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -27, 0, 3),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = config.theme.text,
        Font = Enum.Font.SourceSansBold,
        TextSize = 24,
        Parent = title_bar
    })
    
    -- minimize button
    local minimize_button = self:create_element("TextButton", {
        Name = "MinimizeButton",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -52, 0, 3),
        BackgroundTransparency = 1,
        Text = "−",
        TextColor3 = config.theme.text,
        Font = Enum.Font.SourceSansBold,
        TextSize = 24,
        Parent = title_bar
    })
    
    -- content frame
    local content_frame = self:create_element("Frame", {
        Name = "ContentFrame",
        Size = UDim2.new(1, -20, 1, -40),
        Position = UDim2.new(0, 10, 0, 35),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = window_frame
    })
    
    -- implement custom dragging
    self:make_draggable(window_frame, title_bar)
    
    -- window state variables
    local minimized = false
    local original_size = window_frame.Size
    
    -- close functionality
    close_button.MouseButton1Click:Connect(function()
        window_frame:Destroy()
    end)
    
    -- minimize functionality
    minimize_button.MouseButton1Click:Connect(function()
        minimized = not minimized
        
        if minimized then
            -- store original size and minimize
            original_size = window_frame.Size
            
            tweening_service:Create(
                window_frame,
                TweenInfo.new(config.animation.duration, config.animation.style),
                {Size = UDim2.new(original_size.X.Scale, original_size.X.Offset, 0, 30)}
            ):Play()
            
            -- hide content
            content_frame.Visible = false
        else
            -- restore original size
            tweening_service:Create(
                window_frame,
                TweenInfo.new(config.animation.duration, config.animation.style),
                {Size = original_size}
            ):Play()
            
            -- show content
            content_frame.Visible = true
        end
    end)
    
    -- return the created components
    return {
        window = window_frame,
        title_bar = title_bar,
        content = content_frame,
        set_title = function(new_title)
            title_text.Text = new_title
        end,
        set_size = function(new_size)
            if not minimized then
                original_size = new_size
                window_frame.Size = new_size
            end
        end
    }
end

-- create a button
function ui_library:create_button(parent, text, callback, size, position)
    local button = self:create_element("TextButton", {
        Name = "Button",
        Text = text or "Button",
        Size = size or UDim2.new(1, 0, 0, 30),
        Position = position or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = config.theme.foreground,
        TextColor3 = config.theme.text,
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        BorderSizePixel = 0,
        Parent = parent
    })
    
    self:corner(button)
    
    -- hover and click effects
    local original_color = button.BackgroundColor3
    local hover_color = original_color:Lerp(config.theme.accent, 0.2)
    local press_color = original_color:Lerp(config.theme.accent, 0.4)
    
    button.MouseEnter:Connect(function()
        tweening_service:Create(
            button, 
            TweenInfo.new(config.animation.duration, config.animation.style, config.animation.direction),
            {BackgroundColor3 = hover_color}
        ):Play()
    end)
    
    button.MouseLeave:Connect(function()
        tweening_service:Create(
            button, 
            TweenInfo.new(config.animation.duration, config.animation.style, config.animation.direction),
            {BackgroundColor3 = original_color}
        ):Play()
    end)
    
    button.MouseButton1Down:Connect(function()
        tweening_service:Create(
            button, 
            TweenInfo.new(config.animation.duration/2, config.animation.style, config.animation.direction),
            {BackgroundColor3 = press_color}
        ):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        tweening_service:Create(
            button, 
            TweenInfo.new(config.animation.duration/2, config.animation.style, config.animation.direction),
            {BackgroundColor3 = hover_color}
        ):Play()
    end)
    
    if callback and type(callback) == "function" then
        button.MouseButton1Click:Connect(callback)
    end
    
    -- return interface
    return {
        button = button,
        set_text = function(new_text)
            button.Text = new_text
        end,
        set_callback = function(new_callback)
            if button.MouseButton1Click then
                button.MouseButton1Click:Disconnect()
            end
            button.MouseButton1Click:Connect(new_callback)
        end,
        set_enabled = function(enabled)
            button.Active = enabled
            button.AutoButtonColor = enabled
            button.TextTransparency = enabled and 0 or 0.5
            button.BackgroundColor3 = enabled and original_color or original_color:Lerp(Color3.new(0,0,0), 0.7)
        end
    }
end

-- create a text input
function ui_library:create_textbox(parent, placeholder, callback, size, position)
    local textbox_frame = self:create_element("Frame", {
        Name = "TextboxFrame",
        Size = size or UDim2.new(1, 0, 0, 30),
        Position = position or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = config.theme.foreground,
        BorderSizePixel = 0,
        Parent = parent
    })
    
    self:corner(textbox_frame)
    
    local textbox = self:create_element("TextBox", {
        Name = "Textbox",
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        PlaceholderText = placeholder or "Enter text...",
        PlaceholderColor3 = config.theme.text_dark,
        Text = "",
        TextColor3 = config.theme.text,
        Font = Enum.Font.SourceSans,
        TextSize = 16,
        ClearTextOnFocus = false,
        Parent = textbox_frame
    })
    
    -- focused state visual
    local focused_stroke = self:stroke(textbox_frame, config.theme.accent, 2)
    focused_stroke.Transparency = 1
    
    textbox.Focused:Connect(function()
        tweening_service:Create(
            focused_stroke, 
            TweenInfo.new(config.animation.duration, config.animation.style, config.animation.direction),
            {Transparency = 0}
        ):Play()
    end)
    
    textbox.FocusLost:Connect(function(enter_pressed)
        tweening_service:Create(
            focused_stroke, 
            TweenInfo.new(config.animation.duration, config.animation.style, config.animation.direction),
            {Transparency = 1}
        ):Play()
        
        if callback and type(callback) == "function" then
            callback(textbox.Text, enter_pressed)
        end
    end)
    
    -- interface
    return {
        frame = textbox_frame,
        textbox = textbox,
        get_text = function()
            return textbox.Text
        end,
        set_text = function(text)
            textbox.Text = text
        end,
        clear = function()
            textbox.Text = ""
        end,
        focus = function()
            textbox:CaptureFocus()
        end
    }
end

-- create a toggle switch
function ui_library:create_toggle(parent, text, default, callback, position)
    local toggle_frame = self:create_element("Frame", {
        Name = "ToggleFrame",
        Size = UDim2.new(1, 0, 0, 30),
        Position = position or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local label = self:create_element("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -60, 1, 0),
        BackgroundTransparency = 1,
        Text = text or "Toggle",
        TextColor3 = config.theme.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.SourceSans,
        TextSize = 16,
        Parent = toggle_frame
    })
    
    local toggle_button = self:create_element("Frame", {
        Name = "ToggleButton",
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -45, 0.5, -10),
        BackgroundColor3 = default and config.theme.accent or config.theme.foreground,
        BorderSizePixel = 0,
        Parent = toggle_frame
    })
    
    self:corner(toggle_button, UDim.new(1, 0))
    
    local toggle_circle = self:create_element("Frame", {
        Name = "Circle",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(default and 0.6 or 0.1, 0, 0.5, -8),
        BackgroundColor3 = config.theme.text,
        BorderSizePixel = 0,
        Parent = toggle_button
    })
    
    self:corner(toggle_circle, UDim.new(1, 0))
    
    -- clickable area for better UX
    local click_area = self:create_element("TextButton", {
        Name = "ClickArea",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = toggle_frame
    })
    
    -- toggle state and animation
    local enabled = default or false
    
    local function update_toggle()
        enabled = not enabled
        
        -- animate the circle and background
        tweening_service:Create(
            toggle_circle, 
            TweenInfo.new(config.animation.duration, config.animation.style, config.animation.direction),
            {Position = UDim2.new(enabled and 0.6 or 0.1, 0, 0.5, -8)}
        ):Play()
        
        tweening_service:Create(
            toggle_button, 
            TweenInfo.new(config.animation.duration, config.animation.style, config.animation.direction),
            {BackgroundColor3 = enabled and config.theme.accent or config.theme.foreground}
        ):Play()
        
        if callback and type(callback) == "function" then
            callback(enabled)
        end
    end
    
    click_area.MouseButton1Click:Connect(update_toggle)
    
    -- return toggle interface
    return {
        frame = toggle_frame,
        label = label,
        is_enabled = function()
            return enabled
        end,
        set_enabled = function(state)
            if state ~= enabled then
                update_toggle()
            end
        end,
        set_text = function(new_text)
            label.Text = new_text
        end
    }
end

-- simple slider component
function ui_library:create_slider(parent, text, min, max, default, callback, position)
    min = min or 0
    max = max or 100
    default = default or min
    
    local slider_frame = self:create_element("Frame", {
        Name = "SliderFrame",
        Size = UDim2.new(1, 0, 0, 50),
        Position = position or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local label = self:create_element("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text or "Slider",
        TextColor3 = config.theme.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.SourceSans,
        TextSize = 16,
        Parent = slider_frame
    })
    
    local value_display = self:create_element("TextLabel", {
        Name = "Value",
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -40, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(default),
        TextColor3 = config.theme.accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        Parent = slider_frame
    })
    
    local slider_background = self:create_element("Frame", {
        Name = "Background",
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = config.theme.foreground,
        BorderSizePixel = 0,
        Parent = slider_frame
    })
    
    self:corner(slider_background, UDim.new(0, 3))
    
    local slider_fill = self:create_element("Frame", {
        Name = "Fill",
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = config.theme.accent,
        BorderSizePixel = 0,
        Parent = slider_background
    })
    
    self:corner(slider_fill, UDim.new(0, 3))
    
    local slider_knob = self:create_element("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8),
        BackgroundColor3 = config.theme.text,
        BorderSizePixel = 0,
        Parent = slider_background
    })
    
    self:corner(slider_knob, UDim.new(1, 0))
    
    -- slider clickable area for better UX
    local click_area = self:create_element("TextButton", {
        Name = "ClickArea",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 23),
        BackgroundTransparency = 1,
        Text = "",
        Parent = slider_frame
    })
    
    -- slider functionality
    local is_dragging = false
    local current_value = default
    
    local function update_slider(input_position)
        local relative_position = math.clamp((input_position - slider_background.AbsolutePosition.X) / slider_background.AbsoluteSize.X, 0, 1)
        local new_value = min + ((max - min) * relative_position)
        
        -- round to nearest step if integer slider
        if min % 1 == 0 and max % 1 == 0 then
            new_value = math.floor(new_value + 0.5)
        else
            new_value = math.floor(new_value * 10) / 10 -- round to 1 decimal place
        end
        
        -- update UI
        slider_fill.Size = UDim2.new(relative_position, 0, 1, 0)
        slider_knob.Position = UDim2.new(relative_position, -8, 0.5, -8)
        value_display.Text = tostring(new_value)
        
        -- update value and callback
        if new_value ~= current_value then
            current_value = new_value
            if callback and type(callback) == "function" then
                callback(current_value)
            end
        end
    end
    
    click_area.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            is_dragging = true
            update_slider(input.Position.X)
        end
    end)
    
    click_area.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            is_dragging = false
        end
    end)
    
    slider_knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            is_dragging = true
        end
    end)
    
    slider_knob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            is_dragging = false
        end
    end)
    
    user_input_service.InputChanged:Connect(function(input)
        if is_dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update_slider(input.Position.X)
        end
    end)
    
    -- return slider interface
    return {
        frame = slider_frame,
        get_value = function()
            return current_value
        end,
        set_value = function(value)
            local clamped_value = math.clamp(value, min, max)
            local relative_position = (clamped_value - min) / (max - min)
            
            slider_fill.Size = UDim2.new(relative_position, 0, 1, 0)
            slider_knob.Position = UDim2.new(relative_position, -8, 0.5, -8)
            value_display.Text = tostring(clamped_value)
            
            current_value = clamped_value
            
            if callback and type(callback) == "function" then
                callback(current_value)
            end
        end,
        set_text = function(new_text)
            label.Text = new_text
        end
    }
end

-- create a dropdown menu
function ui_library:create_dropdown(parent, text, options, default_option, callback, position)
    options = options or {}
    
    local dropdown_frame = self:create_element("Frame", {
        Name = "DropdownFrame",
        Size = UDim2.new(1, 0, 0, 30),
        Position = position or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = config.theme.foreground,
        BorderSizePixel = 0,
        ClipsDescendants = true, -- hide dropdown when closed
        ZIndex = 2,
        Parent = parent
    })
    
    self:corner(dropdown_frame)
    
    local dropdown_label = self:create_element("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text or "Dropdown",
        TextColor3 = config.theme.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.SourceSans,
        TextSize = 16,
        ZIndex = 2,
        Parent = dropdown_frame
    })
    
    local selected_option = self:create_element("TextLabel", {
        Name = "SelectedOption",
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = default_option or "",
        TextColor3 = config.theme.accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = Enum.Font.SourceSansBold,
        TextSize = 14,
        ZIndex = 2,
        Parent = dropdown_frame
    })
    
    local arrow = self:create_element("TextLabel", {
        Name = "Arrow",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -25, 0.5, -10),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = config.theme.text,
        Font = Enum.Font.SourceSansBold,
        TextSize = 14,
        ZIndex = 2,
        Parent = dropdown_frame
    })
    
    local options_container = self:create_element("Frame", {
        Name = "OptionsContainer",
        Size = UDim2.new(1, 0, 0, 0), -- will resize based on options
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = config.theme.foreground:Lerp(config.theme.background, 0.5),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 3,
        Parent = dropdown_frame
    })
    
    self:corner(options_container)
    
    -- clickable button for the dropdown
    local dropdown_button = self:create_element("TextButton", {
        Name = "DropdownButton",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 2,
        Parent = dropdown_frame
    })
    
    -- dropdown state
    local is_open = false
    local selected_value = default_option or ""
    
    -- populate options
    local function populate_options()
        -- clear previous options
        for _, child in ipairs(options_container:GetChildren()) do
            if not child:IsA("UICorner") then
                child:Destroy()
            end
        end
        
        -- add new options
        for i, option in ipairs(options) do
            local option_button = self:create_element("TextButton", {
                Name = "Option_" .. i,
                Size = UDim2.new(1, 0, 0, 25),
                Position = UDim2.new(0, 0, 0, (i-1) * 25),
                BackgroundTransparency = 1,
                Text = option,
                TextColor3 = option == selected_value and config.theme.accent or config.theme.text,
                Font = Enum.Font.SourceSans,
                TextSize = 14,
                ZIndex = 3,
                Parent = options_container
            })
            
            option_button.MouseEnter:Connect(function()
                option_button.BackgroundTransparency = 0.8
            end)
            
            option_button.MouseLeave:Connect(function()
                option_button.BackgroundTransparency = 1
            end)
            
            option_button.MouseButton1Click:Connect(function()
                selected_value = option
                selected_option.Text = option
                
                -- update visuals and state
                is_open = false
                
                -- animate closing
                tweening_service:Create(
                    dropdown_frame,
                    TweenInfo.new(config.animation.duration, config.animation.style),
                    {Size = UDim2.new(1, 0, 0, 30)}
                ):Play()
                
                tweening_service:Create(
                    arrow,
                    TweenInfo.new(config.animation.duration, config.animation.style),
                    {Rotation = 0}
                ):Play()
                
                options_container.Visible = false
                
                -- trigger callback
                if callback and type(callback) == "function" then
                    callback(option)
                end
                
                -- update options visual
                populate_options()
            end)
        end
        
        -- update container size
        options_container.Size = UDim2.new(1, 0, 0, #options * 25)
    end
    
    -- initial population
    populate_options()
    
    -- toggle dropdown
    dropdown_button.MouseButton1Click:Connect(function()
        is_open = not is_open
        
        if is_open then
            -- animate opening
            tweening_service:Create(
                dropdown_frame,
                TweenInfo.new(config.animation.duration, config.animation.style),
                {Size = UDim2.new(1, 0, 0, 30 + options_container.AbsoluteSize.Y)}
            ):Play()
            
            tweening_service:Create(
                arrow,
                TweenInfo.new(config.animation.duration, config.animation.style),
                {Rotation = 180}
            ):Play()
            
            options_container.Visible = true
        else
            -- animate closing
            tweening_service:Create(
                dropdown_frame,
                TweenInfo.new(config.animation.duration, config.animation.style),
                {Size = UDim2.new(1, 0, 0, 30)}
            ):Play()
            
            tweening_service:Create(
                arrow,
                TweenInfo.new(config.animation.duration, config.animation.style),
                {Rotation = 0}
            ):Play()
            
            options_container.Visible = false
        end
    end)
    
    -- close dropdown when clicking outside
    user_input_service.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse_position = user_input_service:GetMouseLocation()
            local dropdown_position = dropdown_frame.AbsolutePosition
            local dropdown_size = dropdown_frame.AbsoluteSize
            
            -- check if click is outside dropdown
            if is_open and (
                mouse_position.X < dropdown_position.X or
                mouse_position.X > dropdown_position.X + dropdown_size.X or
                mouse_position.Y < dropdown_position.Y or
                mouse_position.Y > dropdown_position.Y + dropdown_size.Y
            ) then
                is_open = false
                
                -- animate closing
                tweening_service:Create(
                    dropdown_frame,
                    TweenInfo.new(config.animation.duration, config.animation.style),
                    {Size = UDim2.new(1, 0, 0, 30)}
                ):Play()
                
                tweening_service:Create(
                    arrow,
                    TweenInfo.new(config.animation.duration, config.animation.style),
                    {Rotation = 0}
                ):Play()
                
                options_container.Visible = false
            end
        end
    end)
    
    -- return interface
    return {
        frame = dropdown_frame,
        get_selected = function()
            return selected_value
        end,
        set_selected = function(option)
            if table.find(options, option) then
                selected_value = option
                selected_option.Text = option
                populate_options()
                
                if callback and type(callback) == "function" then
                    callback(option)
                end
            end
        end,
        set_options = function(new_options)
            options = new_options
            
            -- reset selected if not in new options
            if not table.find(new_options, selected_value) then
                selected_value = new_options[1] or ""
                selected_option.Text = selected_value
            end
            
            populate_options()
        end,
        add_option = function(option)
            if not table.find(options, option) then
                table.insert(options, option)
                populate_options()
            end
        end,
        remove_option = function(option)
            local index = table.find(options, option)
            if index then
                table.remove(options, index)
                
                -- reset selected if removed
                if selected_value == option then
                    selected_value = options[1] or ""
                    selected_option.Text = selected_value
                end
                
                populate_options()
            end
        end
    }
end

-- create tabs
function ui_library:create_tabbed_window(title, tabs, size, position)
    local window = self:create_window(title, size, position)
    
    -- create tab container at top
    local tabs_frame = self:create_element("Frame", {
        Name = "TabsFrame",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = config.theme.foreground,
        BorderSizePixel = 0,
        Parent = window.content
    })
    
    self:corner(tabs_frame)
    
    -- create content frame below tabs
    local content_frame = self:create_element("Frame", {
        Name = "ContentFrame",
        Size = UDim2.new(1, 0, 1, -35),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundColor3 = config.theme.foreground,
        BorderSizePixel = 0,
        Parent = window.content
    })
    
    self:corner(content_frame)
    
    -- tab management
    local tab_buttons = {}
    local tab_contents = {}
    local current_tab = nil
    
    -- create layout for tab buttons
    local tab_layout = self:create_element("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = tabs_frame
    })
    
    self:padding(tabs_frame, 5)
    
    -- function to create a tab
    local function create_tab(name)
        -- create tab button
        local tab_button = self:create_element("TextButton", {
            Name = "Tab_" .. name,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = name,
            TextColor3 = config.theme.text_dark,
            Font = Enum.Font.SourceSans,
            TextSize = 14,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, -10),
            Parent = tabs_frame
        })
        
        -- create content frame for this tab
        local tab_content = self:create_custom_scrolling_frame(content_frame)
        tab_content.frame.Visible = false
        tab_content.frame.BackgroundTransparency = 1
        
        -- add to tracking tables
        tab_buttons[name] = tab_button
        tab_contents[name] = tab_content
        
        -- set up tab button click behavior
        tab_button.MouseButton1Click:Connect(function()
            self:select_tab(name)
        end)
        
        return tab_content
    end
    
    -- function to select a tab
    function ui_library:select_tab(name)
        if not tab_contents[name] then return end
        
        -- deselect all tabs
        for tab_name, button in pairs(tab_buttons) do
            button.TextColor3 = config.theme.text_dark
            tab_contents[tab_name].frame.Visible = false
        end
        
        -- select the requested tab
        tab_buttons[name].TextColor3 = config.theme.accent
        tab_contents[name].frame.Visible = true
        current_tab = name
    end
    
    -- create tabs from the provided list
    for _, tab_name in ipairs(tabs) do
        create_tab(tab_name)
    end
    
    -- select the first tab by default
    if #tabs > 0 then
        self:select_tab(tabs[1])
    end
    
    -- return the window interface with tab functions
    return {
        window = window.window,
        content = content_frame,
        tabs_frame = tabs_frame,
        add_tab = function(name)
            if not tab_contents[name] then
                local tab = create_tab(name)
                
                -- select if this is the first tab
                if not current_tab then
                    ui_library:select_tab(name)
                end
                
                return tab
            else
                return tab_contents[name]
            end
        end,
        select_tab = function(name)
            ui_library:select_tab(name)
        end,
        get_tab = function(name)
            return tab_contents[name]
        end,
        get_current_tab = function()
            return current_tab
        end
    }
end

-- create a simple notification
function ui_library:create_notification(title, message, duration, notification_type)
    duration = duration or 5
    notification_type = notification_type or "info" -- info, success, error, warning
    
    -- determine color based on type
    local color
    if notification_type == "success" then
        color = config.theme.success
    elseif notification_type == "error" then
        color = config.theme.error
    elseif notification_type == "warning" then
        color = config.theme.warning
    else
        color = config.theme.accent
    end
    
    -- notification container
    if not core_gui:FindFirstChild("NotificationContainer") then
        local container = self:create_element("Frame", {
            Name = "NotificationContainer",
            Size = UDim2.new(0, 300, 1, 0),
            Position = UDim2.new(1, -320, 0, 10),
            BackgroundTransparency = 1,
            Parent = core_gui
        })
        
        local list_layout = self:create_element("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Padding = UDim.new(0, 10),
            Parent = container
        })
    end
    
    local container = core_gui:FindFirstChild("NotificationContainer")
    
    -- create notification
    local notification = self:create_element("Frame", {
        Name = "Notification",
        Size = UDim2.new(1, 0, 0, 80),
        BackgroundColor3 = config.theme.background,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0, 0), -- start off-screen
        Parent = container
    })
    
    self:corner(notification)
    self:stroke(notification, color)
    
    -- notification icon based on type
    local icon_text = "i"
    if notification_type == "success" then
        icon_text = "✓"
    elseif notification_type == "error" then
        icon_text = "✗"
    elseif notification_type == "warning" then
        icon_text = "!"
    end
    
    local icon = self:create_element("TextLabel", {
        Name = "Icon",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(0, 10, 0, 5),
        BackgroundColor3 = color,
        Text = icon_text,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.SourceSansBold,
        TextSize = 18,
        Parent = notification
    })
    
    self:corner(icon, UDim.new(0, 15))
    
    -- notification title
    local title_label = self:create_element("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -60, 0, 25),
        Position = UDim2.new(0, 50, 0, 5),
        BackgroundTransparency = 1,
        Text = title or "Notification",
        TextColor3 = color,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        Parent = notification
    })
    
    -- notification message
    local message_label = self:create_element("TextLabel", {
        Name = "Message",
        Size = UDim2.new(1, -60, 0, 40),
        Position = UDim2.new(0, 50, 0, 35),
        BackgroundTransparency = 1,
        Text = message or "",
        TextColor3 = config.theme.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        Parent = notification
    })
    
    -- close button
    local close_button = self:create_element("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -25, 0, 5),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = config.theme.text_dark,
        Font = Enum.Font.SourceSansBold,
        TextSize = 20,
        Parent = notification
    })
    
    close_button.MouseButton1Click:Connect(function()
        -- animate closing
        local fade_out = tweening_service:Create(
            notification, 
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1.5, 0, 0, notification.Position.Y.Offset)}
        )
        
        fade_out:Play()
        fade_out.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
    
    -- progress bar for duration
    local progress_bar = self:create_element("Frame", {
        Name = "ProgressBar",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Parent = notification
    })
    
    -- slide-in animation
    tweening_service:Create(
        notification, 
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0)}
    ):Play()
    
    -- animate progress bar
    tweening_service:Create(
        progress_bar,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {Size = UDim2.new(0, 0, 0, 2)}
    ):Play()
    
    -- slide-out after duration
    task.delay(duration, function()
        -- check if notification still exists
        if notification and notification.Parent then
            local fade_out = tweening_service:Create(
                notification, 
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Position = UDim2.new(1.5, 0, 0, notification.Position.Y.Offset)}
            )
            
            fade_out:Play()
            fade_out.Completed:Connect(function()
                notification:Destroy()
            end)
        end
    end)
    
    return notification
end

-- create a tooltip
function ui_library:create_tooltip(parent, text)
    local tooltip = self:create_element("Frame", {
        Name = "Tooltip",
        Size = UDim2.new(0, 200, 0, 30),
        BackgroundColor3 = config.theme.background,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 10,
        Parent = self.container
    })
    
    self:corner(tooltip)
    self:stroke(tooltip, config.theme.accent)
    
    local tooltip_text = self:create_element("TextLabel", {
        Name = "Text",
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = config.theme.text,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        ZIndex = 10,
        Parent = tooltip
    })
    
    -- tooltip functionality with improved positioning
    parent.MouseEnter:Connect(function()
        -- dynamically adjust tooltip to content
        tooltip_text.Text = text
        
        -- position tooltip near mouse but ensure it's visible in viewport
        local mouse_pos = user_input_service:GetMouseLocation()
        local viewport_size = workspace.CurrentCamera.ViewportSize
        
        -- calculate dimensions
        tooltip.Size = UDim2.new(0, math.max(150, tooltip_text.TextBounds.X + 20), 0, 30)
        
        -- determine best position
        local pos_x = mouse_pos.X + 20
        if pos_x + tooltip.AbsoluteSize.X > viewport_size.X then
            pos_x = mouse_pos.X - tooltip.AbsoluteSize.X - 10
        end
        
        local pos_y = mouse_pos.Y + 20
        if pos_y + tooltip.AbsoluteSize.Y > viewport_size.Y then
            pos_y = mouse_pos.Y - tooltip.AbsoluteSize.Y - 10
        end
        
        tooltip.Position = UDim2.new(0, pos_x, 0, pos_y)
        tooltip.Visible = true
    end)
    
    parent.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)
    
    -- update tooltip when mouse moves
    parent.MouseMoved:Connect(function(x, y)
        if tooltip.Visible then
            -- ensure tooltip follows mouse but stays in viewport
            local viewport_size = workspace.CurrentCamera.ViewportSize
            
            local pos_x = x + 20
            if pos_x + tooltip.AbsoluteSize.X > viewport_size.X then
                pos_x = x - tooltip.AbsoluteSize.X - 10
            end
            
            local pos_y = y + 20
            if pos_y + tooltip.AbsoluteSize.Y > viewport_size.Y then
                pos_y = y - tooltip.AbsoluteSize.Y - 10
            end
            
            tooltip.Position = UDim2.new(0, pos_x, 0, pos_y)
        end
    end)
    
    return tooltip
end

-- create a color picker
function ui_library:create_color_picker(parent, title, default_color, callback, position)
    default_color = default_color or Color3.fromRGB(255, 255, 255)
    
    -- main container
    local picker_frame = self:create_element("Frame", {
        Name = "ColorPickerFrame",
        Size = UDim2.new(1, 0, 0, 30),
        Position = position or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = config.theme.foreground,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent
    })
    
    self:corner(picker_frame)
    
    -- title
    local title_label = self:create_element("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "Color",
        TextColor3 = config.theme.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.SourceSans,
        TextSize = 16,
        Parent = picker_frame
    })
    
    -- color display
    local color_display = self:create_element("Frame", {
        Name = "ColorDisplay",
        Size = UDim2.new(0, 30, 0, 20),
        Position = UDim2.new(1, -40, 0.5, -10),
        BackgroundColor3 = default_color,
        BorderSizePixel = 0,
        Parent = picker_frame
    })
    
    self:corner(color_display, UDim.new(0, 4))
    
    -- dropdown button (to show full picker)
    local dropdown_button = self:create_element("TextButton", {
        Name = "PickerButton",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = picker_frame
    })
    
    -- color picker panel (expanded view)
    local picker_panel = self:create_element("Frame", {
        Name = "PickerPanel",
        Size = UDim2.new(1, 0, 0, 200),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = config.theme.foreground:Lerp(config.theme.background, 0.3),
        BorderSizePixel = 0,
        Visible = false,
        Parent = picker_frame
    })
    
    self:corner(picker_panel)
    self:padding(picker_panel, 10)
    
    -- color hue slider
    local hue_label = self:create_element("TextLabel", {
        Name = "HueLabel",
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "Hue",
        TextColor3 = config.theme.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        Parent = picker_panel
    })
    
    local hue_slider_bg = self:create_element("Frame", {
        Name = "HueSliderBG",
        Size = UDim2.new(1, 0, 0, 15),
        Position = UDim2.new(0, 0, 0, 25),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = picker_panel
    })
    
    self:corner(hue_slider_bg, UDim.new(0, 4))
    
    -- create hue gradient
    local hue_gradient = self:create_element("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
        }),
        Parent = hue_slider_bg
    })
    
    local hue_slider = self:create_element("Frame", {
        Name = "HueSlider",
        Size = UDim2.new(0, 5, 1, 4),
        Position = UDim2.new(0, 0, 0, -2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = hue_slider_bg
    })
    
    self:corner(hue_slider, UDim.new(1, 0))
    self:stroke(hue_slider, Color3.new(0, 0, 0), 1)
    
    -- saturation/value picker
    local sv_picker = self:create_element("Frame", {
        Name = "SVPicker",
        Size = UDim2.new(1, 0, 0, 100),
        Position = UDim2.new(0, 0, 0, 50),
        BackgroundColor3 = Color3.fromRGB(255, 0, 0), -- will be updated based on hue
        BorderSizePixel = 0,
        Parent = picker_panel
    })
    
    self:corner(sv_picker, UDim.new(0, 4))
    
    -- create white gradient (for saturation)
    local white_gradient = self:create_element("UIGradient", {
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
        Transparency = NumberSequence.new(0, 1),
        Parent = sv_picker
    })
    
    -- create black gradient (for value)
    local black_frame = self:create_element("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = sv_picker
    })
    
    local black_gradient = self:create_element("UIGradient", {
        Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
        Transparency = NumberSequence.new(1, 0),
        Rotation = 90,
        Parent = black_frame
    })
    
    -- picker cursor
    local sv_cursor = self:create_element("Frame", {
        Name = "Cursor",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(1, -5, 0, -5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = sv_picker
    })
    
    self:stroke(sv_cursor, Color3.new(1, 1, 1), 2)
    self:corner(sv_cursor, UDim.new(1, 0))
    
    -- RGB inputs
    local rgb_container = self:create_element("Frame", {
        Name = "RGBContainer",
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.new(0, 0, 0, 160),
        BackgroundTransparency = 1,
        Parent = picker_panel
    })
    
    -- create RGB input boxes
    local function create_rgb_input(index, label)
        local container = self:create_element("Frame", {
            Name = label .. "Container",
            Size = UDim2.new(0.3, -5, 1, 0),
            Position = UDim2.new(0.35 * (index-1), 0, 0, 0),
            BackgroundTransparency = 1,
            Parent = rgb_container
        })
        
        local label_text = self:create_element("TextLabel", {
            Name = "Label",
            Size = UDim2.new(0, 15, 1, 0),
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = config.theme.text,
            Font = Enum.Font.SourceSans,
            TextSize = 14,
            Parent = container
        })
        
        local input_box = self:create_element("TextBox", {
            Name = "Input",
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 20, 0, 0),
            BackgroundColor3 = config.theme.background,
            BorderSizePixel = 0,
            Text = "255",
            TextColor3 = config.theme.text,
            Font = Enum.Font.SourceSans,
            TextSize = 14,
            Parent = container
        })
        
        self:corner(input_box, UDim.new(0, 4))
        
        return input_box
    end
    
    local r_input = create_rgb_input(1, "R")
    local g_input = create_rgb_input(2, "G")
    local b_input = create_rgb_input(3, "B")
    
    -- color state and utils
    local current_color = default_color
    local current_hue = 0
    local current_sat = 1
    local current_val = 1
    
    -- convert RGB to HSV
    local function rgb_to_hsv(color)
        local r, g, b = color.R, color.G, color.B
        local max, min = math.max(r, g, b), math.min(r, g, b)
        local h, s, v
        
        v = max
        
        local delta = max - min
        if max ~= 0 then
            s = delta / max
        else
            s = 0
            h = 0
            return h, s, v
        end
        
        if r == max then
            h = (g - b) / delta
        elseif g == max then
            h = 2 + (b - r) / delta
        else
            h = 4 + (r - g) / delta
        end
        
        h = h * 60
        if h < 0 then h = h + 360 end
        
        return h / 360, s, v
    end
    
    -- convert HSV to RGB
    local function hsv_to_rgb(h, s, v)
        local r, g, b
        
        if s == 0 then
            r, g, b = v, v, v
        else
            local i = math.floor(h * 6)
            local f = h * 6 - i
            local p = v * (1 - s)
            local q = v * (1 - s * f)
            local t = v * (1 - s * (1 - f))
            
            i = i % 6
            
            if i == 0 then r, g, b = v, t, p
            elseif i == 1 then r, g, b = q, v, p
            elseif i == 2 then r, g, b = p, v, t
            elseif i == 3 then r, g, b = p, q, v
            elseif i == 4 then r, g, b = t, p, v
            elseif i == 5 then r, g, b = v, p, q
            end
        end
        
        return Color3.new(r, g, b)
    end
    
    -- update all UI elements based on the current color
    local function update_color_display(update_hsv)
        -- update the color display
        color_display.BackgroundColor3 = current_color
        
        -- update RGB inputs
        r_input.Text = tostring(math.round(current_color.R * 255))
        g_input.Text = tostring(math.round(current_color.G * 255))
        b_input.Text = tostring(math.round(current_color.B * 255))
        
        -- update picker UI
        if update_hsv then
            -- calculate HSV from RGB
            current_hue, current_sat, current_val = rgb_to_hsv(current_color)
            
            -- update hue slider
            hue_slider.Position = UDim2.new(current_hue, -2.5, 0, -2)
            
            -- update SV picker color (based on hue)
            sv_picker.BackgroundColor3 = hsv_to_rgb(current_hue, 1, 1)
            
            -- update cursor position
            sv_cursor.Position = UDim2.new(current_sat, -5, 1 - current_val, -5)
        end
        
        -- trigger callback
        if callback and type(callback) == "function" then
            callback(current_color)
        end
    end
    
    -- initialize with default color
    current_hue, current_sat, current_val = rgb_to_hsv(default_color)
    update_color_display(true)
    
    -- hue slider interaction
    hue_slider_bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local connection
            
            local function update_hue(input_obj)
                local offset = math.clamp((input_obj.Position.X - hue_slider_bg.AbsolutePosition.X) / hue_slider_bg.AbsoluteSize.X, 0, 1)
                current_hue = offset
                hue_slider.Position = UDim2.new(offset, -2.5, 0, -2)
                
                -- update SV picker base color and final color
                sv_picker.BackgroundColor3 = hsv_to_rgb(current_hue, 1, 1)
                current_color = hsv_to_rgb(current_hue, current_sat, current_val)
                update_color_display(false)
            end
            
            update_hue(input)
            
            connection = user_input_service.InputChanged:Connect(function(input_obj)
                if input_obj.UserInputType == Enum.UserInputType.MouseMovement then
                    update_hue(input_obj)
                end
            end)
            
            user_input_service.InputEnded:Connect(function(input_obj)
                if input_obj.UserInputType == Enum.UserInputType.MouseButton1 then
                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
        end
    end)
    
    -- SV picker interaction
    sv_picker.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local connection
            
            local function update_sv(input_obj)
                local relative_x = math.clamp((input_obj.Position.X - sv_picker.AbsolutePosition.X) / sv_picker.AbsoluteSize.X, 0, 1)
                local relative_y = math.clamp((input_obj.Position.Y - sv_picker.AbsolutePosition.Y) / sv_picker.AbsoluteSize.Y, 0, 1)
                
                current_sat = relative_x
                current_val = 1 - relative_y
                
                sv_cursor.Position = UDim2.new(relative_x, -5, relative_y, -5)
                
                -- update color
                current_color = hsv_to_rgb(current_hue, current_sat, current_val)
                update_color_display(false)
            end
            
            update_sv(input)
            
            connection = user_input_service.InputChanged:Connect(function(input_obj)
                if input_obj.UserInputType == Enum.UserInputType.MouseMovement then
                    update_sv(input_obj)
                end
            end)
            
            user_input_service.InputEnded:Connect(function(input_obj)
                if input_obj.UserInputType == Enum.UserInputType.MouseButton1 then
                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
        end
    end)
    
    -- RGB input handling
    local function update_from_rgb_inputs()
        local r = tonumber(r_input.Text) or 0
        local g = tonumber(g_input.Text) or 0
        local b = tonumber(b_input.Text) or 0
        
        r = math.clamp(r, 0, 255) / 255
        g = math.clamp(g, 0, 255) / 255
        b = math.clamp(b, 0, 255) / 255
        
        current_color = Color3.new(r, g, b)
        update_color_display(true)
    end
    
    r_input.FocusLost:Connect(update_from_rgb_inputs)
    g_input.FocusLost:Connect(update_from_rgb_inputs)
    b_input.FocusLost:Connect(update_from_rgb_inputs)
    
    -- toggle picker panel
    local is_open = false
    
    dropdown_button.MouseButton1Click:Connect(function()
        is_open = not is_open
        
        if is_open then
            -- expand frame to show picker
            tweening_service:Create(
                picker_frame,
                TweenInfo.new(config.animation.duration, config.animation.style),
                {Size = UDim2.new(1, 0, 0, 240)}
            ):Play()
            
            picker_panel.Visible = true
        else
            -- collapse frame
            tweening_service:Create(
                picker_frame,
                TweenInfo.new(config.animation.duration, config.animation.style),
                {Size = UDim2.new(1, 0, 0, 30)}
            ):Play()
            
            task.delay(config.animation.duration, function()
                picker_panel.Visible = false
            end)
        end
    end)
    
    -- return interface
    return {
        frame = picker_frame,
        get_color = function()
            return current_color
        end,
        set_color = function(color)
            current_color = color
            update_color_display(true)
        end
    }
end

-- set theme colors
function ui_library:set_theme(new_theme)
    for key, value in pairs(new_theme) do
        if config.theme[key] then
            config.theme[key] = value
        end
    end
end

return ui_library
