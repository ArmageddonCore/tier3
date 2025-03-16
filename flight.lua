getgenv().fly_config = {
    controls = {
        toggle = Enum.KeyCode.V,
        boost = Enum.KeyCode.LeftShift,
    },
    movement = {
        base_speed = 100,
        boost_multiplier = 7.5,
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
        enabled = false,
        show_velocity = true,
    }
}
