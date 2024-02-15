local constants = {
    bigLinearShift = 1.0, -- 1 metre
    smallLinearShift = 0.025,
    bigRotShift = math.pi / 16, -- like in the game with <m> and <n>
    smallRotShift = math.pi / 320,
    smallScaleShift = 1.004,
    bigScaleShift = 1.04,
    scaleMax = 2,
    scaleMin = 0.5,
    smallSkewShift = 0.005,
    bigSkewShift = 0.05,
    skewCosMax = 0.7,

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
        skewXY = 'skewXY',
        skewXZ = 'skewXZ',
        skewYZ = 'skewYZ',
        traslX = 'traslX',
        traslY = 'traslY',
        traslZ = 'traslZ',
        undo = 'undo',
    },
    transfTypes = {
        none = 'none',
        rot = 'rot',
        scale = 'scale',
        trasl = 'trasl',
        skew = 'skew',
        undo = 'undo',
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
        undoButton = 'lollo_con_mover_undo_button',
        warningWindowWithMessage = 'lollo_con_mover_warning_window_with_message',
        warningWindowWithState = 'lollo_con_mover_warning_window_with_state',
    }
}

return constants
