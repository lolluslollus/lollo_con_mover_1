local arrayUtils = require('lolloConMover.arrayUtils')
local constants = require('lolloConMover.constants')
local edgeUtils = require('lolloConMover.edgeUtils')
local logger = require ('lolloConMover.logger')
local stateHelpers = require('lolloConMover.stateHelpers')
-- local transfUtils = require('lolloConMover.transfUtils')
local transfUtilsUG = require('transf')


local actions = {
    bulldozeConstruction = function(conId)
        if not(edgeUtils.isValidAndExistingId(conId)) then
            -- logger.print('bulldozeConstruction cannot bulldoze construction with id =', conId or 'NIL', 'because it is not valid or does not exist')
            return
        end

        local proposal = api.type.SimpleProposal.new()
        -- LOLLO NOTE there are asymmetries how different tables are handled.
        -- This one requires this system, UG says they will document it or amend it.
        proposal.constructionsToRemove = { conId }
        -- proposal.constructionsToRemove[1] = constructionId -- fails to add
        -- proposal.constructionsToRemove:add(constructionId) -- fails to add

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        -- context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is 'ignore errors'; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('bulldozeConstruction success = ', success)
                -- logger.print('bulldozeConstruction result = ') logger.debugPrint(result)
            end
        )
    end,
    renameConstruction = function(conId, newName)
        logger.print('renameConstruction starting, conId =', (conId or 'NIL'), 'newName =', newName or 'NIL')
        if not(edgeUtils.isValidAndExistingId(conId)) then return end

        local cmd = api.cmd.make.setName(conId, newName or '')
        api.cmd.sendCommand(
            cmd,
            function(result, success)
                logger.print('renameConstruction success = ', success)
                -- logger.print('renameConstruction result = ') logger.debugPrint(result)
            end
        )
    end,
}
actions.shiftConstruction = function(conId, newTransf, isIgnoreErrors)
    if not(edgeUtils.isValidAndExistingId(conId)) then
        logger.print('shiftConstruction cannot shift construction with id =', conId or 'NIL', 'because it is not valid or does not exist')
        return
    end
    local oldCon = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
    if not(oldCon) then
        logger.print('shiftConstruction cannot shift construction with id =', conId or 'NIL', 'because it cannot be read')
        return
    end

    local newCon = api.type.SimpleProposal.ConstructionEntity.new()
    newCon.fileName = oldCon.fileName

    local newParams = {}
    for oldKey, oldValue in pairs(oldCon.params) do
        newParams[oldKey] = oldValue
    end
    newParams.seed = oldCon.params.seed + 1
    newCon.params = newParams

    local oldConTransf = transfUtilsUG.new(oldCon.transf:cols(0), oldCon.transf:cols(1), oldCon.transf:cols(2), oldCon.transf:cols(3))
    local newConTransf = transfUtilsUG.mul(oldConTransf, newTransf)
    newCon.transf = api.type.Mat4f.new(
        api.type.Vec4f.new(newConTransf[1], newConTransf[2], newConTransf[3], newConTransf[4]),
        api.type.Vec4f.new(newConTransf[5], newConTransf[6], newConTransf[7], newConTransf[8]),
        api.type.Vec4f.new(newConTransf[9], newConTransf[10], newConTransf[11], newConTransf[12]),
        api.type.Vec4f.new(newConTransf[13], newConTransf[14], newConTransf[15], newConTransf[16])
    )

    newCon.playerEntity = api.engine.util.getPlayer() -- otherwise, I cannot select it again

    -- newCon.headquarters = oldCon.fileName == 'asset/headquarter.con' -- LOLLO TODO check what to do when shifting headquarters

    local proposal = api.type.SimpleProposal.new()
    -- LOLLO NOTE there are asymmetries how different tables are handled.
    -- This one requires this system, UG says they will document it or amend it.
    proposal.constructionsToRemove = { conId }
    -- proposal.constructionsToRemove[1] = constructionId -- fails to add
    -- proposal.constructionsToRemove:add(constructionId) -- fails to add
    proposal.constructionsToAdd[1] = newCon

    -- proposal.old2new = {
    --     -- [conId] = 1 -- dumps
    --     -- [conId] = 0
    --     -- conId, 1 -- works but does nothing
    --     conId, 0
    --     -- conId, -1
    -- }

    local oldConName = api.engine.getComponent(conId, api.type.ComponentType.NAME)
    if oldConName then oldConName = oldConName.name else oldConName = nil end

    local context = api.type.Context:new()
    context.checkTerrainAlignment = true -- default is false, true gives smoother Z
    context.cleanupStreetGraph = true -- default is false
    context.gatherBuildings = true  -- default is false
    -- context.gatherFields = true -- default is true
    -- context.player = api.engine.util.getPlayer() -- default is -1
    -- local cmd = api.cmd.make.buildProposal(proposal, context, true) -- the 3rd param is 'ignore errors'; wrong proposals will be discarded anyway
    api.cmd.sendCommand(
        api.cmd.make.buildProposal(proposal, context, isIgnoreErrors), -- the 3rd param is 'ignore errors'; wrong proposals will be discarded anyway,
        function(result, success)
            xpcall(
                function()
                    if success then
                        logger.print('shiftConstruction succeeded')
                        if result and result.resultEntities and #result.resultEntities == 1 then
                            logger.print('result.resultEntities[1] =', result.resultEntities[1])
                            actions.renameConstruction(result.resultEntities[1], oldConName)
                        end
                    else
                        logger.print('shiftConstruction failed')
                        logger.print('shiftConstruction result = ') logger.debugPrint(result)
                    end
                end,
                logger.errorHandler
            )
        end
    )
end

local function handleEvent(src, id, name, args)
    if id ~= constants.eventId then return end

    xpcall(
        function()
            logger.print('handleEvent firing, src =', src, ', id =', id, ', name =', name, ', args =') logger.debugPrint(args)

            if name == constants.events.shift_construction then
                local newTransf = {
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    (args[constants.transNames.xShift] or 0), (args[constants.transNames.yShift] or 0), (args[constants.transNames.zShift] or 0), 1
                }
                actions.shiftConstruction(args.conId, newTransf, args.isIgnoreErrors)
            elseif name == constants.events.toggle_notaus then
                logger.print('state before =') logger.debugPrint(stateHelpers.getState())
                local state = stateHelpers.getState()
                state.is_on = not(not(args))
                logger.print('state after =') logger.debugPrint(stateHelpers.getState())
            end
        end,
        logger.errorHandler
    )
end

return {
    handleEvent = handleEvent
}
