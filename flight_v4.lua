repeat task.wait() until game:IsLoaded()

-- Flight V3 Configuration
getgenv().fly_config = {
    controls = {
        toggle = Enum.KeyCode.V,
        boost = Enum.KeyCode.LeftShift,
    },
    movement = {
        base_speed = 100,
        boost_multiplier = 4,
        acceleration = 6,
        turn_speed = 3,
        hover_force = 2.1,
        tilt = {
            forward_angle = -20, -- degrees for forward tilt
            application_rate = 0.08, -- how quickly tilt applies (0-1)
        }
    },
    appearance = {
        trail_enabled = false,
        trail_color = Color3.fromRGB(255, 255, 255),
        trail_transparency = 0.5,
        trail_lifetime = 1,
    },
    options = {
        noclip = true,
        disable_animations = true,
        gravity_enabled = false,
        notification_duration = 2,
    },
    debug = {
        enabled = true,
        show_velocity = true,
    }
}

-- Core services with error handling
local services = {
    user_input_service = nil,
    starter_gui = nil,
    run = nil,
    players = nil,
    debris = nil
}

local function safeGetService(serviceName)
    local success, service = pcall(function()
        return cloneref(game:GetService(serviceName))
    end)
    
    if success then
        return service
    else
        warn("Flight V3: Failed to get service: " .. serviceName)
        return nil
    end
end

-- Initialize services safely
services.user_input_service = safeGetService("UserInputService")
services.starter_gui = safeGetService("StarterGui")
services.run = safeGetService("RunService")
services.players = safeGetService("Players")
services.debris = safeGetService("Debris")

-- Check if essential services are available
if not (services.user_input_service and services.run and services.players) then
    warn("Flight V3: Critical services unavailable. Flight script cannot run.")
    return
end

-- State management
local state = {
    camera = workspace.CurrentCamera,
    player = services.players.LocalPlayer,
    char = nil,
    root = nil,
    humanoid = nil,
    animator = nil,
    velocity = Vector3.new(),
    connection = nil,
    noclip_connection = nil,
    flying = false,
    trail = nil,
    current_tilt = 0,
    target_tilt = 0,
    forward_movement = false,
    safe_mode = false -- Protection mode in case of errors
}

-- Notification function
local function notify(title, text)
    if services.starter_gui then
        pcall(function()
            services.starter_gui:SetCore("SendNotification", {
                Title = title,
                Text = text,
                Duration = fly_config.options.notification_duration or 2
            })
        end)
    end
end

-- Character management
local function set_char(char)
    if not char then return end
    
    state.char = char
    
    -- Safely get character components
    local success, result = pcall(function()
        local root = char:WaitForChild("HumanoidRootPart", 5)
        local humanoid = char:WaitForChild("Humanoid", 5)
        local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 2)
        
        return {
            root = root,
            humanoid = humanoid,
            animator = animator
        }
    end)
    
    if success and result.root and result.humanoid then
        state.root = result.root
        state.humanoid = result.humanoid
        state.animator = result.animator
    else
        warn("Flight V3: Character setup failed")
        state.safe_mode = true
    end
end

-- Animation handling
local function disable_animations()
    if not fly_config.options.disable_animations then return end
    
    if state.animator then
        pcall(function()
            for _, track in pairs(state.animator:GetPlayingAnimationTracks()) do
                track:Stop()
            end
        end)
    end
end

-- Noclip functionality
local function noclip()
    if not state.char then return end
    
    pcall(function()
        for _, part in pairs(state.char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

-- Reset collisions when flight is disabled
local function reset_collisions()
    if not state.char then return end
    
    pcall(function()
        for _, part in pairs(state.char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end)
end

-- Create visual trail
local function create_trail()
    if not fly_config.appearance.trail_enabled or not state.root then return end
    
    pcall(function()
        if state.trail then state.trail:Destroy() end
        
        local attachment1 = Instance.new("Attachment")
        attachment1.Position = Vector3.new(0, 0, -0.5)
        attachment1.Parent = state.root
        
        local attachment2 = Instance.new("Attachment")
        attachment2.Position = Vector3.new(0, 0, 0.5)
        attachment2.Parent = state.root
        
        local trail = Instance.new("Trail")
        trail.Attachment0 = attachment1
        trail.Attachment1 = attachment2
        trail.Color = ColorSequence.new(fly_config.appearance.trail_color)
        trail.Transparency = NumberSequence.new(fly_config.appearance.trail_transparency)
        trail.Lifetime = fly_config.appearance.trail_lifetime
        trail.Parent = state.root
        
        state.trail = trail
    end)
end

-- Remove trail
local function remove_trail()
    pcall(function()
        if state.trail then
            state.trail:Destroy()
            state.trail = nil
        end
    end)
end

-- Direction vector calculation with safe checks
local function calculate_move_vector()
    local baseVel = Vector3.new()
    local input = services.user_input_service
    local camera = state.camera
    
    if not input or not camera then return baseVel end
    
    -- Only handle movement if no text box is focused
    if not input:GetFocusedTextBox() then
        if input:IsKeyDown(Enum.KeyCode.W) then
            baseVel = baseVel + (camera.CFrame.LookVector * fly_config.movement.base_speed)
            state.forward_movement = true
        end
        if input:IsKeyDown(Enum.KeyCode.S) then
            baseVel = baseVel - (camera.CFrame.LookVector * fly_config.movement.base_speed)
            state.forward_movement = true
        end
        if input:IsKeyDown(Enum.KeyCode.A) then
            baseVel = baseVel - (camera.CFrame.RightVector * fly_config.movement.base_speed)
        end
        if input:IsKeyDown(Enum.KeyCode.D) then
            baseVel = baseVel + (camera.CFrame.RightVector * fly_config.movement.base_speed)
        end
        if input:IsKeyDown(Enum.KeyCode.Space) then
            baseVel = baseVel + (camera.CFrame.UpVector * fly_config.movement.base_speed)
        end
        
        -- Apply boost if key is pressed
        if input:IsKeyDown(fly_config.controls.boost) then
            baseVel = baseVel * fly_config.movement.boost_multiplier
        end
        
        -- If no forward/backward keys are pressed, reset forward movement flag
        if not (input:IsKeyDown(Enum.KeyCode.W) or input:IsKeyDown(Enum.KeyCode.S)) then
            state.forward_movement = false
        end
    end
    
    return baseVel
end

-- Flight physics with forward tilt and smooth turning
local function flight(delta)
    -- Safety check
    if state.safe_mode then return end
    
    -- Basic validation
    if not (state.root and state.humanoid) then return end
    
    -- Calculate movement vector
    local baseVel = calculate_move_vector()
    
    pcall(function()
        local root = state.root
        if not root or root.Anchored then return end
        
        -- Set humanoid state for flight
        state.humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        state.humanoid.PlatformStand = true
        
        -- Disable animations if configured
        if fly_config.options.disable_animations then
            disable_animations()
        end
        
        -- Smoothly interpolate velocity
        state.velocity = state.velocity:Lerp(
            baseVel,
            math.clamp(delta * fly_config.movement.acceleration, 0, 1)
        )
        
        -- Apply hover force
        root.Velocity = state.velocity + Vector3.new(0, fly_config.movement.hover_force, 0)
        
        -- Calculate tilt based on forward movement
        state.target_tilt = state.forward_movement and 
            math.rad(fly_config.movement.tilt.forward_angle) or 0
        
        -- Smoothly apply or remove tilt
        state.current_tilt = state.forward_movement 
            and state.current_tilt + (state.target_tilt - state.current_tilt) * fly_config.movement.tilt.application_rate
            or 0
        
        -- Prepare orientation for root part
        root.RotVelocity = Vector3.new()
        
        -- Create target orientation with tilt
        local lookVector = state.camera.CFrame.LookVector
        local rightVector = state.camera.CFrame.RightVector
        
        -- Create the base look-at orientation
        local baseOrientation = CFrame.lookAt(
            root.Position, 
            root.Position + lookVector
        )
        
        -- Apply tilt by rotating around the right axis
        local tiltRotation = CFrame.Angles(state.current_tilt, 0, 0)
        local targetOrientation = baseOrientation * tiltRotation
        
        -- Smoothly interpolate to target orientation
        root.CFrame = root.CFrame:Lerp(
            targetOrientation,
            math.clamp(delta * fly_config.movement.turn_speed, 0, 1)
        )
    end)
end

-- Debug visualization
local function update_debug()
    if not fly_config.debug.enabled then return end
    
    pcall(function()
        -- Create or update debug info
        local debugText = state.debugText
        
        if not debugText then
            debugText = Instance.new("TextLabel")
            debugText.Size = UDim2.new(0, 200, 0, 100)
            debugText.Position = UDim2.new(0, 10, 0, 10)
            debugText.BackgroundTransparency = 0.5
            debugText.BackgroundColor3 = Color3.new(0, 0, 0)
            debugText.TextColor3 = Color3.new(1, 1, 1)
            debugText.TextXAlignment = Enum.TextXAlignment.Left
            debugText.TextYAlignment = Enum.TextYAlignment.Top
            debugText.Parent = state.player.PlayerGui:FindFirstChild("ScreenGui") or Instance.new("ScreenGui", state.player.PlayerGui)
            state.debugText = debugText
        end
        
        local info = "Flight V3 Debug\n"
        if fly_config.debug.show_velocity and state.velocity then
            info = info .. "Velocity: " .. tostring(state.velocity.Magnitude) .. "\n"
        end
        info = info .. "Flying: " .. tostring(state.flying) .. "\n"
        info = info .. "Tilt: " .. tostring(math.deg(state.current_tilt)) .. "°\n"
        
        debugText.Text = info
    end)
end

-- Enable flight
local function enable_flight()
    state.flying = true
    state.velocity = state.root and state.root.Velocity or Vector3.new()
    
    -- Create main flight update connection
    state.connection = services.run.Heartbeat:Connect(flight)
    
    -- Apply noclip if enabled
    if fly_config.options.noclip then
        state.noclip_connection = services.run.Stepped:Connect(noclip)
    end
    
    -- Create visual trail if enabled
    if fly_config.appearance.trail_enabled then
        create_trail()
    end
    
    -- Set gravity if configured
    if not fly_config.options.gravity_enabled and state.humanoid then
        state.humanoid.UseJumpPower = false
    end
    
    -- Enable debug if configured
    if fly_config.debug.enabled then
        services.run.RenderStepped:Connect(update_debug)
    end
    
    notify("Flight V3", "Enabled")
end

-- Disable flight
local function disable_flight()
    state.flying = false
    
    -- Clean up connections
    if state.connection then
        state.connection:Disconnect()
        state.connection = nil
    end
    
    if state.noclip_connection then
        state.noclip_connection:Disconnect()
        state.noclip_connection = nil
    end
    
    -- Reset humanoid state
    if state.humanoid then
        pcall(function()
            state.humanoid.PlatformStand = false
            state.humanoid:ChangeState(Enum.HumanoidStateType.Running)
            
            -- Reset jump settings
            state.humanoid.UseJumpPower = true
        end)
    end
    
    -- Reset collisions
    reset_collisions()
    
    -- Remove trail
    remove_trail()
    
    -- Reset tilt immediately
    state.current_tilt = 0
    state.target_tilt = 0
    
    notify("Flight V3", "Disabled")
end

-- Monitor camera changes
workspace.Changed:Connect(function()
    state.camera = workspace.CurrentCamera
end)

-- Handle character changes
state.player.CharacterAdded:Connect(set_char)
if state.player.Character then
    set_char(state.player.Character)
end

-- Key input handling
services.user_input_service.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    -- Toggle flight
    if input.KeyCode == fly_config.controls.toggle then
        if state.flying then
            disable_flight()
        else
            -- Only enable if we have valid character components
            if state.root and state.humanoid then
                enable_flight()
            else
                notify("Flight V3", "Cannot fly - character not ready")
            end
        end
    end
end)

-- Dynamic configuration
-- Function to update configuration at runtime
getgenv().updateFlightConfig = function(newConfig)
    for category, settings in pairs(newConfig) do
        if fly_config[category] then
            for setting, value in pairs(settings) do
                fly_config[category][setting] = value
            end
        end
    end
    notify("Flight V3", "Configuration updated")
end

-- Initial notification
notify("Flight V3", "Loaded successfully")
