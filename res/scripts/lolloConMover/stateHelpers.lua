local logger = require('lolloConMover.logger')

local persistent_state = {}

local _initState = function()
    if persistent_state.is_on == nil then
        persistent_state.is_on = false
    end
end

local funcs = {
    initState = _initState,
    loadState = function(state)
        if state then
            persistent_state = state
        end

        _initState()
    end,
    getState = function()
        return persistent_state
    end,
    saveState = function()
        _initState()
        return persistent_state
    end,
}

_initState() -- fires when loading

return funcs