-- command framework module
local command_system = {}
command_system.__index = command_system

local players_service = game:GetService("Players")
local run_service = game:GetService("RunService")
local selection_service = game:GetService("Selection")
local teams_service = game:GetService("Teams")
local debris_service = game:GetService("Debris")
local ts = game:GetService("TweenService")

local commands = {}
local command_aliases = {}
local command_cooldowns = {}
local command_permissions = {}
local command_metadata = {}

local function deep_copy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = deep_copy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function parse_args(args_string)
    local args = {}
    local current_arg = ""
    local in_quotes = false
    
    for i = 1, #args_string do
        local char = args_string:sub(i, i)
        
        if char == '"' then
            in_quotes = not in_quotes
        elseif char == " " and not in_quotes then
            if current_arg ~= "" then
                table.insert(args, current_arg)
                current_arg = ""
            end
        else
            current_arg = current_arg .. char
        end
    end
    
    if current_arg ~= "" then
        table.insert(args, current_arg)
    end
    
    return args
end

local function find_player(name, executor)
    if name:lower() == "me" then
        return executor
    elseif name:lower() == "all" then
        return players_service:GetPlayers()
    elseif name:lower() == "others" then
        local all_players = players_service:GetPlayers()
        local filtered = {}
        for _, player in ipairs(all_players) do
            if player ~= executor then
                table.insert(filtered, player)
            end
        end
        return filtered
    elseif name:lower() == "random" then
        local all_players = players_service:GetPlayers()
        return {all_players[math.random(1, #all_players)]}
    else
        local found_players = {}
        for _, player in ipairs(players_service:GetPlayers()) do
            if player.Name:lower():sub(1, #name) == name:lower() or 
               player.DisplayName:lower():sub(1, #name) == name:lower() then
                table.insert(found_players, player)
            end
        end
        
        if #found_players == 0 then
            return nil
        elseif #found_players == 1 then
            return found_players[1]
        else
            return found_players
        end
    end
end

function command_system.register_command(name, callback, metadata)
    assert(type(name) == "string", "command name must be a string")
    assert(type(callback) == "function", "command callback must be a function")
    
    name = name:lower()
    commands[name] = callback
    
    if metadata then
        metadata.usage = metadata.usage or name
        metadata.description = metadata.description or "no description provided"
        metadata.aliases = metadata.aliases or {}
        metadata.cooldown = metadata.cooldown or 0
        metadata.permission_level = metadata.permission_level or 0
        
        command_metadata[name] = metadata
        
        for _, alias in ipairs(metadata.aliases) do
            command_aliases[alias:lower()] = name
        end
    else
        command_metadata[name] = {
            usage = name,
            description = "no description provided",
            aliases = {},
            cooldown = 0,
            permission_level = 0
        }
    end
end

function command_system.execute(input, executor)
    local split_input = parse_args(input)
    local cmd_name = table.remove(split_input, 1):lower()
    
    if command_aliases[cmd_name] then
        cmd_name = command_aliases[cmd_name]
    end
    
    local command_func = commands[cmd_name]
    
    if not command_func then
        return false, "command not found: " .. cmd_name
    end
    
    local metadata = command_metadata[cmd_name]
    
    -- check permissions
    local executor_permission = command_permissions[executor.UserId] or 0
    if executor_permission < metadata.permission_level then
        return false, "insufficient permissions to run this command"
    end
    
    -- check cooldown
    local cooldown_key = executor.UserId .. "_" .. cmd_name
    local current_time = tick()
    if command_cooldowns[cooldown_key] and 
       current_time - command_cooldowns[cooldown_key] < metadata.cooldown then
        local remaining = math.ceil(metadata.cooldown - (current_time - command_cooldowns[cooldown_key]))
        return false, "command on cooldown for " .. remaining .. " second(s)"
    end
    
    -- set cooldown
    command_cooldowns[cooldown_key] = current_time
    
    -- execute command
    local success, result = pcall(function()
        return command_func(executor, split_input)
    end)
    
    if not success then
        return false, "error executing command: " .. result
    end
    
    return true, result
end

function command_system.get_commands()
    local result = {}
    for name, metadata in pairs(command_metadata) do
        table.insert(result, {
            name = name,
            metadata = deep_copy(metadata)
        })
    end
    return result
end

function command_system.set_permission(user_id, level)
    command_permissions[user_id] = level
end

function command_system.get_permission(user_id)
    return command_permissions[user_id] or 0
end

-- initialize advanced tracker command
local tracker_data = {}

command_system.register_command("track", function(executor, args)
    if #args < 1 then
        return "usage: track <player> [options]"
    end
    
    local target = find_player(args[1], executor)
    if not target then
        return "player not found: " .. args[1]
    end
    
    if type(target) == "table" then
        return "too many matching players, be more specific"
    end
    
    -- parse options
    local options = {
        color = Color3.fromRGB(255, 0, 0),
        interval = 0.1,
        duration = 30,
        show_path = true,
        show_trajectory = true,
        show_stats = true,
        path_length = 60
    }
    
    for i = 2, #args do
        local option = args[i]:split("=")
        if #option == 2 then
            local key, value = option[1]:lower(), option[2]
            
            if key == "color" then
                local rgb = value:split(",")
                if #rgb == 3 then
                    options.color = Color3.fromRGB(
                        tonumber(rgb[1]) or 255,
                        tonumber(rgb[2]) or 0,
                        tonumber(rgb[3]) or 0
                    )
                end
            elseif key == "interval" then
                options.interval = tonumber(value) or 0.1
                options.interval = math.max(0.05, options.interval)
            elseif key == "duration" then
                options.duration = tonumber(value) or 30
                options.duration = math.clamp(options.duration, 1, 300)
            elseif key == "path" then
                options.show_path = value:lower() == "true"
            elseif key == "trajectory" then
                options.show_trajectory = value:lower() == "true"
            elseif key == "stats" then
                options.show_stats = value:lower() == "true"
            elseif key == "pathlength" then
                options.path_length = tonumber(value) or 60
                options.path_length = math.clamp(options.path_length, 5, 300)
            end
        end
    end
    
    -- clean up existing tracking data for this target
    if tracker_data[target.UserId] then
        if tracker_data[target.UserId].cleanup then
            tracker_data[target.UserId].cleanup()
        end
    end
    
    -- initialize tracking
    local character = target.Character
    if not character then
        return "target has no character"
    end
    
    local humanoid_root_part = character:FindFirstChild("HumanoidRootPart")
    if not humanoid_root_part then
        return "target has no HumanoidRootPart"
    end
    
    local cleanup_funcs = {}
    local path_positions = {}
    local velocity_history = {}
    local last_position = humanoid_root_part.Position
    
    -- create lasso
    local lasso = Instance.new("SelectionPartLasso")
    lasso.Humanoid = character:FindFirstChildOfClass("Humanoid")
    lasso.Part = humanoid_root_part
    lasso.Visible = true
    lasso.Color3 = options.color
    lasso.Transparency = 0.5
    lasso.Parent = workspace
    
    table.insert(cleanup_funcs, function()
        lasso:Destroy()
    end)
    
    -- create path visualizer
    local path_folder = Instance.new("Folder")
    path_folder.Name = "TrackPath_" .. target.Name
    path_folder.Parent = workspace
    
    table.insert(cleanup_funcs, function()
        path_folder:Destroy()
    end)
    
    -- create stats display
    local billboard_gui = Instance.new("BillboardGui")
    billboard_gui.Name = "TrackStats"
    billboard_gui.AlwaysOnTop = true
    billboard_gui.Size = UDim2.new(0, 200, 0, 100)
    billboard_gui.StudsOffset = Vector3.new(0, 3, 0)
    billboard_gui.Adornee = humanoid_root_part
    billboard_gui.Parent = humanoid_root_part
    
    local stats_frame = Instance.new("Frame")
    stats_frame.BackgroundTransparency = 0.5
    stats_frame.BackgroundColor3 = Color3.new(0, 0, 0)
    stats_frame.Size = UDim2.new(1, 0, 1, 0)
    stats_frame.Parent = billboard_gui
    
    local stats_text = Instance.new("TextLabel")
    stats_text.BackgroundTransparency = 1
    stats_text.Size = UDim2.new(1, 0, 1, 0)
    stats_text.TextColor3 = Color3.new(1, 1, 1)
    stats_text.TextScaled = true
    stats_text.Font = Enum.Font.Code
    stats_text.Text = "Initializing..."
    stats_text.Parent = stats_frame
    
    if not options.show_stats then
        billboard_gui.Enabled = false
    end
    
    table.insert(cleanup_funcs, function()
        billboard_gui:Destroy()
    end)
    
    -- trajectory prediction visualizer
    local trajectory_part = Instance.new("Part")
    trajectory_part.Name = "TrackTrajectory"
    trajectory_part.Anchored = true
    trajectory_part.CanCollide = false
    trajectory_part.Transparency = 0.7
    trajectory_part.Material = Enum.Material.Neon
    trajectory_part.Color = options.color
    trajectory_part.Shape = Enum.PartType.Ball
    trajectory_part.Size = Vector3.new(0.5, 0.5, 0.5)
    trajectory_part.Parent = workspace
    
    if not options.show_trajectory then
        trajectory_part.Transparency = 1
    end
    
    table.insert(cleanup_funcs, function()
        trajectory_part:Destroy()
    end)
    
    -- connection for movement tracking
    local update_connection = run_service.Heartbeat:Connect(function(dt)
        if not character or not character:FindFirstChild("HumanoidRootPart") or 
           not character.Parent or not target.Parent then
            -- Target is gone, clean up tracking
            for _, func in ipairs(cleanup_funcs) do
                func()
            end
            if tracker_data[target.UserId] then
                tracker_data[target.UserId] = nil
            end
            return
        end
        
        local current_position = humanoid_root_part.Position
        local velocity = (current_position - last_position) / dt
        last_position = current_position
        
        -- Calculate acceleration
        table.insert(velocity_history, velocity)
        if #velocity_history > 10 then
            table.remove(velocity_history, 1)
        end
        
        local avg_velocity = Vector3.new(0, 0, 0)
        local acceleration = Vector3.new(0, 0, 0)
        
        if #velocity_history >= 2 then
            avg_velocity = velocity_history[#velocity_history]
            local prev_velocity = velocity_history[#velocity_history-1]
            acceleration = (avg_velocity - prev_velocity) / dt
        end
        
        -- Update stats display
        if options.show_stats then
            local speed = velocity.Magnitude
            local height = current_position.Y
            local direction = velocity.Unit
            
            local stats = string.format(
                "Player: %s\nSpeed: %.2f studs/s\nHeight: %.2f\nAccel: %.2f studs/s²\nDir: %.2f, %.2f, %.2f",
                target.Name,
                speed,
                height,
                acceleration.Magnitude,
                direction.X, direction.Y, direction.Z
            )
            
            stats_text.Text = stats
        end
        
        -- Update path visualization
        if options.show_path then
            table.insert(path_positions, current_position)
            if #path_positions > options.path_length then
                table.remove(path_positions, 1)
            end
            
            -- Clear previous path
            path_folder:ClearAllChildren()
            
            -- Draw new path
            for i = 2, #path_positions do
                local segment = Instance.new("Part")
                segment.Anchored = true
                segment.CanCollide = false
                segment.Transparency = 0.5
                segment.Material = Enum.Material.Neon
                segment.Color = options.color
                segment.Name = "PathSegment"
                
                local start_pos = path_positions[i-1]
                local end_pos = path_positions[i]
                local direction = (end_pos - start_pos).Unit
                local distance = (end_pos - start_pos).Magnitude
                
                segment.Size = Vector3.new(0.2, 0.2, distance)
                segment.CFrame = CFrame.new(start_pos:Lerp(end_pos, 0.5), end_pos)
                segment.Parent = path_folder
                
                -- Fade transparency based on age
                local alpha = (i-1) / #path_positions
                segment.Transparency = 0.5 + (alpha * 0.5)
            end
        end
        
        -- Update trajectory prediction
        if options.show_trajectory then
            local predicted_position = current_position + (velocity * 2)
            trajectory_part.Position = predicted_position
        end
    end)
    
    table.insert(cleanup_funcs, function()
        if update_connection then
            update_connection:Disconnect()
        end
    end)
    
    -- Set up cleanup after duration
    local timer = task.delay(options.duration, function()
        for _, func in ipairs(cleanup_funcs) do
            func()
        end
        tracker_data[target.UserId] = nil
    end)
    
    table.insert(cleanup_funcs, function()
        task.cancel(timer)
    end)
    
    -- Store tracker data
    tracker_data[target.UserId] = {
        target = target,
        start_time = tick(),
        duration = options.duration,
        cleanup = function()
            for _, func in ipairs(cleanup_funcs) do
                func()
            end
        end
    }
    
    return "tracking " .. target.Name .. " for " .. options.duration .. " seconds"
end, {
    description = "track a player with advanced visualization",
    usage = "track <player> [color=r,g,b] [interval=0.1] [duration=30] [path=true/false] [trajectory=true/false] [stats=true/false] [pathlength=60]",
    aliases = {"follow", "trace"},
    cooldown = 3,
    permission_level = 1
})

command_system.register_command("stoptrack", function(executor, args)
    if #args < 1 then
        local count = 0
        for _, data in pairs(tracker_data) do
            data.cleanup()
            count = count + 1
        end
        tracker_data = {}
        return "stopped tracking " .. count .. " players"
    end
    
    local target = find_player(args[1], executor)
    if not target then
        return "player not found: " .. args[1]
    end
    
    if type(target) == "table" then
        return "too many matching players, be more specific"
    end
    
    if tracker_data[target.UserId] then
        tracker_data[target.UserId].cleanup()
        tracker_data[target.UserId] = nil
        return "stopped tracking " .. target.Name
    else
        return target.Name .. " is not being tracked"
    end
end, {
    description = "stop tracking a player or all players",
    usage = "stoptrack [player]",
    aliases = {"untrack", "unfollow"},
    cooldown = 1,
    permission_level = 1
})

-- helper function to initialize the command system on the server
function command_system.initialize_server(config)
    config = config or {}
    
    local default_admins = config.default_admins or {}
    local prefix = config.prefix or "!"
    
    for _, admin_id in ipairs(default_admins) do
        command_system.set_permission(admin_id, 100) 
    end
    
    players_service.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            if message:sub(1, #prefix) == prefix then
                local command_text = message:sub(#prefix + 1)
                local success, result = command_system.execute(command_text, player)
                
                if result then
                    local message = Instance.new("Message")
                    message.Text = success and "Command: " .. result or "Error: " .. result
                    message.Parent = player
                    debris_service:AddItem(message, 3)
                end
            end
        end)
    end)
    
    for _, player in ipairs(players_service:GetPlayers()) do
        player.Chatted:Connect(function(message)
            if message:sub(1, #prefix) == prefix then
                local command_text = message:sub(#prefix + 1)
                local success, result = command_system.execute(command_text, player)
                
                if result then
                    local message = Instance.new("Message")
                    message.Text = success and "Command: " .. result or "Error: " .. result
                    message.Parent = player
                    debris_service:AddItem(message, 3)
                end
            end
        end)
    end
    
    print("command system initialized with prefix: " .. prefix)
    return command_system
end

return command_system
