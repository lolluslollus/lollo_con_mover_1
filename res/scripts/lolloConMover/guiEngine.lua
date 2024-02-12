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

return {
    handleEvent = function(id, name, args)
        if name ~= 'select' then return end

        -- logger.print('LOLLO caught gui event, id = ', id, ' name = ', name, ' args = ') logger.debugPrint(args)
        local _state = stateHelpers.getState()
        if not(_state) or not(_state.is_on) then return end

        local _conId = args
        if not(_conId) or not(utils.isValidAndExistingId(_conId)) then return end

        local con = api.engine.getComponent(_conId, api.type.ComponentType.CONSTRUCTION)
        if not(con) or not(con.fileName) then return end

        if con.fileName == 'lollo_freestyle_train_station/auto_fence.con' then return end -- it crashes with no useful messages with the auto fence

        xpcall(
            function()
                guiHelpers.showMoveWindow(
                    _conId,
                    function(fieldName, fieldValue, isIgnoreErrors, isAbsoluteNWSE)
                        logger.print('showMoveWindow callback firing, isAbsoluteNWSE = ' .. tostring(isAbsoluteNWSE))
                        local refTransf = constants.idTransf
                        if not(isAbsoluteNWSE) then
                            local cameraData = game.gui.getCamera() -- UG TODO the api does not work
                            if not(cameraData) then
                                logger.warn('cannot get camera')
                            else
                                -- cameraData looks like posX, posY, distance, rotZ (not normalised), tanZ (max = 1)
                                local cameraRotZ = cameraData[4] or 0
                                logger.print('cameraData[4] =', cameraData[4] or 'NIL')
                                logger.print('cameraData[4] normalised =', math.fmod(cameraData[4], math.pi * 2))
                                -- same as cameraData[4] % (math.pi * 2)
                                refTransf = transfUtilsUG.rotZ(cameraRotZ + math.pi / 2)
                            end
                        else
                            -- LOLLO NOTE must read the con transf again coz it does not carry over
                            local _con = api.engine.getComponent(_conId, api.type.ComponentType.CONSTRUCTION)
                            refTransf = transfUtilsUG.new(_con.transf:cols(0), _con.transf:cols(1), _con.transf:cols(2), {x = 0, y = 0, z = 0, w = 1})
                        end
                        _sendScriptEvent(
                            constants.events.move_construction,
                            {
                                refTransf = refTransf,
                                conId = _conId,
                                [fieldName] = fieldValue,
                                isIgnoreErrors = isIgnoreErrors and true or false
                            }
                        )
                    end
                )
            end,
            logger.xpErrorHandler
        )
    end,
    guiInit = function()
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
    end,
}
