-- NOTE that the state must be read-only here coz we are in the GUI thread
local constants = require('lolloConMover.constants')
local guiHelpers = require('lolloConMover.guiHelpers')
local logger = require('lolloConMover.logger')
local stateHelpers = require ('lolloConMover.stateHelpers')
local transfUtilsUG = require('transf')
local utils = require('lolloConMover.utils')


local function _sendScriptEvent(name, args)
    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
        string.sub(debug.getinfo(1, 'S').source, 1), constants.eventId, name, args)
    )
end

local function handleEvent(id, name, args)
    if name == 'select' then
        -- logger.print('LOLLO caught gui event, id = ', id, ' name = ', name, ' args = ') logger.debugPrint(args)
        local _state = stateHelpers.getState()
        if not(_state) or not(_state.is_on) then return end

        if not(args) or not(utils.isValidAndExistingId(args)) then return end -- probably redundant

        local con = api.engine.getComponent(args, api.type.ComponentType.CONSTRUCTION)
        if not(con) or not(con.fileName) then return end

        xpcall(
            function()
                guiHelpers.showShiftWindow(
                    args, -- conId
                    function(fieldName, fieldValue, isIgnoreErrors)
                        _sendScriptEvent(
                            constants.events.shift_construction,
                            {
                                conId = args,
                                [fieldName] = fieldValue,
                                isIgnoreErrors = isIgnoreErrors
                            }
                        )
                    end
                )
            end,
            logger.xpErrorHandler
        )
    end
end

local function guiInit()
    local _state = stateHelpers.getState()

    guiHelpers.initNotausToggleButton(
        _state.is_on,
        function(isOn)
            _sendScriptEvent(constants.events.toggle_notaus, isOn)
        end
    )
end

return {
    guiInit = guiInit,
    handleEvent = handleEvent,
}
