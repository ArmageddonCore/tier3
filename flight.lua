repeat task.wait() until game:IsLoaded()

getgenv().fly_config = {
    controls = {
        toggle = Enum.KeyCode.V,
        boost = Enum.KeyCode.LeftShift,
    },
    movement = {
        base_speed = 100,
        boost_multiplier = 7.5, -- multiplies base speed
        acceleration = 6, -- adds velocity to the current velocity, used for smoothing
        turn_speed = 3, -- adds more fine tuned veloicty to the current velocity, used for further smoothness
        hover_force = 2.1
    },
    options = {
        noclip = true -- set to false if you don't want noclip while flying
    }
}

local services = {
    user_input_service = cloneref(game:GetService("UserInputService")),
    starter_gui = cloneref(game:GetService("StarterGui")),
    run = cloneref(game:GetService("RunService")),
    players = cloneref(game:GetService("Players"))
}

local state = {
    camera = workspace.CurrentCamera,
    player = services.players.LocalPlayer,
    char = nil,
    root = nil,
    humanoid = nil,
    animator = nil,
    velocity = Vector3.new(),
    connection = nil,
    noclip_connection = nil
}

local notify = function(title, text)
    services.starter_gui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 2
    })
end

local set_char = function(char)
    state.char = char
    state.root = char:WaitForChild("HumanoidRootPart")
    state.humanoid = char:WaitForChild("Humanoid")
    state.animator = state.humanoid:WaitForChild("Animator")
end

local disable_animations = function()
    if state.animator then
        for _, track in pairs(state.animator:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end
end

local noclip = function()
    if state.char then
        for _, part in pairs(state.char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

local flight = function(delta)
    local baseVel = Vector3.new()
    
    if not services.user_input_service:GetFocusedTextBox() then
        if services.user_input_service:IsKeyDown(Enum.KeyCode.W) then
            baseVel = baseVel + (state.camera.CFrame.LookVector * fly_config.movement.base_speed)
        end
        if services.user_input_service:IsKeyDown(Enum.KeyCode.S) then
            baseVel = baseVel - (state.camera.CFrame.LookVector * fly_config.movement.base_speed)
        end
        if services.user_input_service:IsKeyDown(Enum.KeyCode.A) then
            baseVel = baseVel - (state.camera.CFrame.RightVector * fly_config.movement.base_speed)
        end
        if services.user_input_service:IsKeyDown(Enum.KeyCode.D) then
            baseVel = baseVel + (state.camera.CFrame.RightVector * fly_config.movement.base_speed)
        end
        if services.user_input_service:IsKeyDown(Enum.KeyCode.Space) then
            baseVel = baseVel + (state.camera.CFrame.UpVector * fly_config.movement.base_speed)
        end
        if services.user_input_service:IsKeyDown(fly_config.controls.boost) then
            baseVel = baseVel * fly_config.movement.boost_multiplier
        end
    end

    if state.root and state.humanoid then
        local part = state.root:GetRootPart()
        if part.Anchored then return end

        state.humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        state.humanoid.PlatformStand = true
        
        disable_animations()

        state.velocity = state.velocity:Lerp(
            baseVel,
            math.clamp(delta * fly_config.movement.acceleration, 0, 1)
        )

        part.Velocity = state.velocity + Vector3.new(0, fly_config.movement.hover_force, 0)

        if part ~= state.root then
            part.RotVelocity = Vector3.new()
            part.CFrame = part.CFrame:Lerp(CFrame.lookAt(
                part.Position,
                part.Position + state.camera.CFrame.LookVector
            ), math.clamp(delta * fly_config.movement.turn_speed, 0, 1))
        else
            part.RotVelocity = Vector3.new()
            part.CFrame = CFrame.lookAt(
                part.Position,
                part.Position + state.camera.CFrame.LookVector
            )
        end
    end
end

workspace.Changed:Connect(function()
    state.camera = workspace.CurrentCamera
end)

state.player.CharacterAdded:Connect(set_char)
if state.player.Character then
    set_char(state.player.Character)
end

services.user_input_service.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == fly_config.controls.toggle then
        if state.connection then
            state.connection:Disconnect()
            state.connection = nil
            if state.noclip_connection then
                state.noclip_connection:Disconnect()
                state.noclip_connection = nil
            end
            if state.humanoid then
                state.humanoid.PlatformStand = false
                state.humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
            if state.char then
                for _, part in pairs(state.char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            notify("flight", "disabled")
        else
            state.velocity = state.root.Velocity
            state.connection = services.run.Heartbeat:Connect(flight)
            if fly_config.options.noclip then
                state.noclip_connection = services.run.Stepped:Connect(noclip)
            end
            notify("flight", "enabled")
        end
    end
end)

notify("flight", "loaded successfully")
