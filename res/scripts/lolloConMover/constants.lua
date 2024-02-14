local constants = {
    bigLinearShift = 1.0, -- 1 metre
    bigRotShift = math.pi / 16, -- like in the game with <m> and <n>
    smallLinearShift = 0.05,
    smallRotShift = math.pi / 320,
    scaleShift = 1.05,
    scaleMax = 2,
    scaleMin = 0.5,
    skewShift = 0.05,
    skewMax = 5,

    idTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1},

    eventId = '__lollo_construction_mover__',
    events = {
        move_construction = 'move_construction',
        toggle_notaus = 'toggle_notaus'
    },
    transfNames = {
        rotX = 'rotX',
        rotY = 'rotY',
        rotZ = 'rotZ',
        scaleX = 'scaleX',
        scaleY = 'scaleY',
        scaleZ = 'scaleZ',
        skewX = 'skewX',
        skewY = 'skewY',
        skewZ = 'skewZ',
        traslX = 'traslX',
        traslY = 'traslY',
        traslZ = 'traslZ',
    },
    transfTypes = {
        none = 'none',
        rot = 'rot',
        scale = 'scale',
        trasl = 'trasl',
        skew = 'skew',
    },

    guiIds = {
        cameraIcons = {
            east = 'lollo_con_mover_camera_icon_east',
            north = 'lollo_con_mover_camera_icon_north',
            south = 'lollo_con_mover_camera_icon_south',
            west = 'lollo_con_mover_camera_icon_west',
        },
        operationOnOffButton = 'lollo_con_mover_on_off_button',
        moveWindow = 'lollo_con_mover_move_window',
        warningWindowWithMessage = 'lollo_con_mover_warning_window_with_message',
        warningWindowWithState = 'lollo_con_mover_warning_window_with_state',
    }
}

return constants
