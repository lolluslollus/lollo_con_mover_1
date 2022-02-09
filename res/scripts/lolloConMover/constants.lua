local constants = {
    bigLinearShift = 1.0, -- 1 metre
    bigRotShift = math.pi / 16, -- like in the game with <m> and <n>
    smallLinearShift = 0.1,
    smallRotShift = math.pi / 160,

    eventId = '__lollo_construction_mover__',
    events = {
        shift_construction = 'shift_construction',
        toggle_notaus = 'toggle_notaus'
    },
    transNames = {
        rotX = 'rotX',
        rotY = 'rotY',
        rotZ = 'rotZ',
        xShift = 'shiftX',
        yShift = 'shiftY',
        zShift = 'shiftY',
    },

    windowXShift = -200,
    windowYShift = 100,
}

return constants
