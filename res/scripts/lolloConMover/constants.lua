local constants = {
    bigLinearShift = 1.0, -- 1 metre
    bigRotShift = math.pi / 16, -- like in the game with <m> and <n>
    smallLinearShift = 0.05,
    smallRotShift = math.pi / 320,

    idTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1},

    eventId = '__lollo_construction_mover__',
    events = {
        shift_construction = 'shift_construction',
        toggle_notaus = 'toggle_notaus'
    },
    transNames = {
        rotX = 'rotX',
        rotY = 'rotY',
        rotZ = 'rotZ',
        shiftX = 'shiftX',
        shiftY = 'shiftY',
        shiftZ = 'shiftZ',
    },

    windowXShift = -200,
    windowYShift = 100,

    guiIds = {
        cameraIcons = {
            east = 'lollo_con_mover_camera_icon_east',
            north = 'lollo_con_mover_camera_icon_north',
            south = 'lollo_con_mover_camera_icon_south',
            west = 'lollo_con_mover_camera_icon_west',
        },
        operationOnOffButton = 'lollo_con_mover_on_off_button',
        shiftWindow = 'lollo_con_mover_shift_window',
        warningWindowWithMessage = 'lollo_con_mover_warning_window_with_message',
        warningWindowWithState = 'lollo_con_mover_warning_window_with_state',
    }
}

return constants
