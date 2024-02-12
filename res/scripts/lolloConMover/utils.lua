local logger = require ('lolloConMover.logger')

local utils = {}

utils.isValidId = function(id)
    return type(id) == 'number' and id > 0
end

utils.isValidAndExistingId = function(id)
    return utils.isValidId(id) and api.engine.entityExists(id)
end

utils.getDummyGroundFaces = function()
    --[[
        LOLLO NOTE
        constructions that do not contain
        ground faces, terrain alignments, edges or depot/station/industry/town building definitions
        are not treated like constructions in the game,
        ie they cannot be selected.
        That's why we make a dummy ground face, which is practically invisible and harmless.
    ]]
    return {
        {
            face = {
                {0.1, -0.1, 0.0, 1.0},
                {0.1, 0.1, 0.0, 1.0},
                {-0.1, 0.1, 0.0, 1.0},
                {-0.1, -0.1, 0.0, 1.0},
            },
            modes = {
                {
                    type = 'FILL',
                    key = 'shared/asphalt_01.gtex.lua' --'shared/gravel_03.gtex.lua'
                }
            }
        },
    }
end

utils.getDummyTerrainAlignmentLists = function()
    -- LOLLO NOTE this thing with the empty faces is required , otherwise the game will make its own alignments, with spikes and all on bridges or tunnels.
    return { {
        type = 'EQUAL',
        optional = true,
        faces =  { }
    } }
end

utils.renameConstruction = function(conId, newName)
    -- logger.print('renameConstruction starting, conId =', (conId or 'NIL'), 'newName =', newName or 'NIL')
    if not(utils.isValidAndExistingId(conId)) then return end

    xpcall(
        function ()
            api.cmd.sendCommand(
                api.cmd.make.setName(conId, newName or ''),
                function(result, isSuccess)
                    if not(isSuccess) then
                        logger.warn('renameConstruction failed')
                    end
                    -- logger.print('renameConstruction success = ', isSuccess)
                    -- logger.print('renameConstruction result = ') logger.debugPrint(result)
                end
            )
        end,
        logger.xpErrorHandler
    )
end

return utils
