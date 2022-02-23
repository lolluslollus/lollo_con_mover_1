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
                        local cameraRotZTransf = constants.idTransf
                        local cameraData = game.gui.getCamera()
                        if not(cameraData) then
                            logger.warn('cannot get camera')
                        else
                            -- cameraData looks like posX, posY, distance, rotZ (not normalised), tanZ (max = 1)
                            local cameraRotZ = cameraData[4] or 0
                            logger.print('cameraData[4] =', cameraData[4] or 'NIL')
                            logger.print('cameraData[4] normalised =', math.fmod(cameraData[4], math.pi * 2))
                            -- same as cameraData[4] % (math.pi * 2)
                            cameraRotZTransf = transfUtilsUG.rotZ(cameraRotZ + math.pi / 2)
                        end
                        _sendScriptEvent(
                            constants.events.shift_construction,
                            {
                                cameraRotZTransf = cameraRotZTransf,
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
    if not(_state) then
        logger.err('cannot read state at guiInit')
        return
    end

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
