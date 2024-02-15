local arrayUtils = require('lolloConMover.arrayUtils')
local constants = require('lolloConMover.constants')
local logger = require ('lolloConMover.logger')
local stateHelpers = require('lolloConMover.stateHelpers')
local transfUtils = require('lolloConMover.transfUtils')
local transfUtilsUG = require('transf')
local utils = require('lolloConMover.utils')


local _getNewRotateTransf = function(oldConTransf, deltaTransf)
    -- this rotates the construction around its own axes,
    -- not around the world axes.
    local newConTransf = transfUtilsUG.mul(oldConTransf, deltaTransf)
    return newConTransf
end
local _getNewScaleTransf = function(oldConTransf, deltaTransf)
    -- this scales the construction around its own axes,
    -- not around the world axes.
    local newConTransf = transfUtilsUG.mul(oldConTransf, deltaTransf)
    local posX0 = transfUtils.getVec123Transformed({0, 0, 0}, newConTransf)
    local posX1 = transfUtils.getVec123Transformed({1, 0, 0}, newConTransf)
    local posY0 = transfUtils.getVec123Transformed({0, 0, 0}, newConTransf)
    local posY1 = transfUtils.getVec123Transformed({0, 1, 0}, newConTransf)
    local posZ0 = transfUtils.getVec123Transformed({0, 0, 0}, newConTransf)
    local posZ1 = transfUtils.getVec123Transformed({0, 0, 1}, newConTransf)
    local lengthX = transfUtils.getPositionsDistance(posX0, posX1)
    local lengthY = transfUtils.getPositionsDistance(posY0, posY1)
    local lengthZ = transfUtils.getPositionsDistance(posZ0, posZ1)
    if logger.isExtendedLog() then
        print('_getNewScaleTransf calculated positions =')
        debugPrint(posX0) debugPrint(posX1)
        debugPrint(posY0) debugPrint(posY1)
        debugPrint(posZ0) debugPrint(posZ1)
        print('_getNewScaleTransf calculated lengths = ' .. tostring(lengthX) .. ' ' .. lengthY .. ' ' .. lengthZ .. ' ')
    end

    if lengthX < constants.scaleMin or lengthX > constants.scaleMax
    or lengthY < constants.scaleMin or lengthY > constants.scaleMax
    or lengthZ < constants.scaleMin or lengthZ > constants.scaleMax then
        logger.print('_getNewScaleTransf wants to leave because it does not want to go out of bounds')
        return nil
    end

    logger.print('_getNewScaleTransf is about to return newConTransf =') logger.debugPrint(newConTransf)
    return newConTransf
end
local _getNewSkewTransf = function(oldConTransf, deltaTransf)
    -- this skews the construction around its own axes,
    -- not around the world axes.
    local newConTransf = transfUtilsUG.mul(oldConTransf, deltaTransf)
    -- make a cube to estimate the skews. Its vertexes are North West Low, South East High etc
    local posSWL = transfUtils.getVec123Transformed({-0.5, -0.5, -0.5}, newConTransf)
    local posSEL = transfUtils.getVec123Transformed({0.5, -0.5, -0.5}, newConTransf)
    local posNEL = transfUtils.getVec123Transformed({0.5, 0.5, -0.5}, newConTransf)
    -- local posNWL = transfUtils.getVec123Transformed({-0.5, 0.5, -0.5}, newConTransf)
    -- local posSWH = transfUtils.getVec123Transformed({-0.5, -0.5, 0.5}, newConTransf)
    local posSEH = transfUtils.getVec123Transformed({0.5, -0.5, 0.5}, newConTransf)
    local posNEH = transfUtils.getVec123Transformed({0.5, 0.5, 0.5}, newConTransf)
    -- local posNWH = transfUtils.getVec123Transformed({-0.5, 0.5, 0.5}, newConTransf)
-- LOLLO TODO fix these estimators
-- they look OK now, but rotation and skew combine in funny ways, so I'd need an undo feature!
    -- check XY skew
    local lengthXY1 = transfUtils.getPositionsDistance({posSWL[1], posSWL[2], 0}, {posSEL[1], posSEL[2], 0})
    local lengthXY2 = transfUtils.getPositionsDistance({posSEL[1], posSEL[2], 0}, {posNEL[1], posNEL[2], 0})
    local lengthXY3 = transfUtils.getPositionsDistance({posNEL[1], posNEL[2], 0}, {posSWL[1], posSWL[2], 0})
    local cosXY = (lengthXY1 * lengthXY1 + lengthXY2 * lengthXY2 - lengthXY3 * lengthXY3) / 2 / lengthXY1 / lengthXY2
    logger.print('_getNewSkewTransf found cosXY = ' .. tostring(cosXY))
    if math.abs(cosXY) > constants.skewCosMax then
        logger.print('_getNewSkewTransf wants to leave because it does not want to go out of bounds')
        return nil
    end
    -- check XZ skew
    local lengthXZ1 = transfUtils.getPositionsDistance({posSWL[1], 0, posSWL[3]}, {posSEL[1], 0, posSEL[3]})
    local lengthXZ2 = transfUtils.getPositionsDistance({posSEL[1], 0, posSEL[3]}, {posSEH[1], 0, posSEH[3]})
    local lengthXZ3 = transfUtils.getPositionsDistance({posSEH[1], 0, posSEH[3]}, {posSWL[1], 0, posSWL[3]})
    local cosXZ = (lengthXZ1 * lengthXZ1 + lengthXZ2 * lengthXZ2 - lengthXZ3 * lengthXZ3) / 2 / lengthXZ1 / lengthXZ2
    logger.print('_getNewSkewTransf found cosXZ = ' .. tostring(cosXZ))
    if math.abs(cosXZ) > constants.skewCosMax then
        logger.print('_getNewSkewTransf wants to leave because it does not want to go out of bounds')
        return nil
    end
    -- check YZ skew
    local lengthYZ1 = transfUtils.getPositionsDistance({0, posSEL[2], posSEL[3]}, {0, posNEL[2], posNEL[3]})
    local lengthYZ2 = transfUtils.getPositionsDistance({0, posNEL[2], posNEL[3]}, {0, posNEH[2], posNEH[3]})
    local lengthYZ3 = transfUtils.getPositionsDistance({0, posNEH[2], posNEH[3]}, {0, posSEL[2], posSEL[3]})
    local cosYZ = (lengthYZ1 * lengthYZ1 + lengthYZ2 * lengthYZ2 - lengthYZ3 * lengthYZ3) / 2 / lengthYZ1 / lengthYZ2
    logger.print('_getNewSkewTransf found cosYZ = ' .. tostring(cosYZ))
    if math.abs(cosYZ) > constants.skewCosMax then
        logger.print('_getNewSkewTransf wants to leave because it does not want to go out of bounds')
        return nil
    end

    logger.print('_getNewSkewTransf is about to return newConTransf =') logger.debugPrint(newConTransf)
    return newConTransf
end
local _getNewTraslTransf = function(oldConTransf, deltaTransf)
    -- this will traslate the construction along the world axes
    local newConTransf = {}
    for i = 1, 12, 1 do
       newConTransf[i] = oldConTransf[i]
    end
    for i = 13, 15, 1 do
        newConTransf[i] = oldConTransf[i] + deltaTransf[i]
    end
    newConTransf[16] = oldConTransf[16]

    return newConTransf
end

local actions = {
    bulldozeConstruction = function(conId)
        if not(utils.isValidAndExistingId(conId)) then
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
            function(result, isSuccess)
                logger.print('bulldozeConstruction success = ', isSuccess)
                -- logger.print('bulldozeConstruction result = ') logger.debugPrint(result)
            end
        )
    end,
}
actions.moveConstruction = function(conId, deltaTransf, transfType, isIgnoreErrors, forcedConTransf)
    if not(utils.isValidAndExistingId(conId)) then
        logger.print('moveConstruction cannot move construction with id =', conId or 'NIL', 'because it is not valid or does not exist')
        return
    end
    local oldCon = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
    if not(oldCon) then
        logger.print('moveConstruction cannot move construction with id =', conId or 'NIL', 'because it cannot be read')
        return
    end
    if not(transfType) or transfType == constants.transfTypes.none then
        logger.print('moveConstruction cannot move construction with id =', conId or 'NIL', 'because the transf type is none')
        return
    end

    local newCon = api.type.SimpleProposal.ConstructionEntity.new()
    newCon.fileName = oldCon.fileName

    local newParams = arrayUtils.cloneDeepOmittingFields(oldCon.params, nil, true)
    newParams.seed = newParams.seed + 1
    newCon.params = newParams
    -- LOLLO NOTE the following looks OK but fails with particular cons like 'lollo_freestyle_train_station/auto_fence.con'
    -- local newParams = {}
    -- for oldKey, oldValue in pairs(oldCon.params) do
    --     newParams[oldKey] = oldValue
    -- end
    -- newParams.seed = oldCon.params.seed + 1
    -- newCon.params = newParams

    local frozenEdgesCountBak = not(oldCon.frozenEdges) and 0 or #oldCon.frozenEdges
    local frozenNodesCountBak = not(oldCon.frozenNodes) and 0 or #oldCon.frozenNodes
    local paramsBak = arrayUtils.cloneDeepOmittingFields(newParams, {'seed'})

    local oldConTransf = transfUtilsUG.new(oldCon.transf:cols(0), oldCon.transf:cols(1), oldCon.transf:cols(2), oldCon.transf:cols(3))
    -- logger.print('oldConTransf =') logger.debugPrint(oldConTransf)
    local newConTransf = nil
    if forcedConTransf ~= nil then
        newConTransf = forcedConTransf
    elseif transfType == constants.transfTypes.rot then
        newConTransf = _getNewRotateTransf(oldConTransf, deltaTransf)
    elseif transfType == constants.transfTypes.scale then
        newConTransf = _getNewScaleTransf(oldConTransf, deltaTransf)
    elseif transfType == constants.transfTypes.skew then
        newConTransf = _getNewSkewTransf(oldConTransf, deltaTransf)
    elseif transfType == constants.transfTypes.trasl then
        newConTransf = _getNewTraslTransf(oldConTransf, deltaTransf)
    end
    if not(newConTransf) then return end
    -- logger.print('newConTransf =') logger.debugPrint(newConTransf)
    newCon.transf = api.type.Mat4f.new(
        api.type.Vec4f.new(newConTransf[1], newConTransf[2], newConTransf[3], newConTransf[4]),
        api.type.Vec4f.new(newConTransf[5], newConTransf[6], newConTransf[7], newConTransf[8]),
        api.type.Vec4f.new(newConTransf[9], newConTransf[10], newConTransf[11], newConTransf[12]),
        api.type.Vec4f.new(newConTransf[13], newConTransf[14], newConTransf[15], newConTransf[16])
    )

    newCon.playerEntity = api.engine.util.getPlayer() -- otherwise, I cannot select it again

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
    -- context.cleanupStreetGraph = true -- default is false, true seems to make trouble
    context.gatherBuildings = true  -- default is false
    -- context.gatherFields = true -- default is true
    -- context.player = api.engine.util.getPlayer() -- default is -1
    -- local cmd = api.cmd.make.buildProposal(proposal, context, true) -- the 3rd param is 'ignore errors'; wrong proposals will be discarded anyway
    -- UG TODO this does not catch critical errors, they come anyway and crash the game
    local expectedResult = api.engine.util.proposal.makeProposalData(proposal, context)
    if expectedResult.errorState.critical then
        logger.print('moveConstruction would create a critical error, leaving')
        return
    end
    api.cmd.sendCommand(
        api.cmd.make.buildProposal(proposal, context, isIgnoreErrors), -- the 3rd param is 'ignore errors'; wrong proposals will be discarded anyway,
        function(result, isSuccess)
            if not(isSuccess) then
                logger.print('moveConstruction failed')
                -- logger.print('moveConstruction result = ') logger.debugPrint(result)
                return
            end

            logger.print('moveConstruction succeeded')
            -- local errorState = result.resultProposalData.errorState
            -- {
            --     critical = false,
            --     messages = {
            --     },
            --     warnings = {
            --     },
            -- }
            logger.print('result.errorState = ') logger.debugPrint(result.resultProposalData.errorState)
            if not(result) or not(result.resultEntities)
            or (type(result.resultEntities) ~= 'userdata' and type(result.resultEntities) ~= 'table')
            or not(result.resultEntities[1]) then
                logger.warn('result.resultEntities[1] not available')
                return
            end

            logger.print('result.resultEntities[1] =', result.resultEntities[1])
            utils.renameConstruction(result.resultEntities[1], oldConName)
            if conId ~= result.resultEntities[1] then
                logger.warn('oddly, conId =', conId)
                return
            end

            xpcall(
                function()
                    if frozenEdgesCountBak == 0 and frozenNodesCountBak == 0 then
                        logger.print('no frozen edges and no frozen nodes: upgrade skipped')
                        return
                    end
                    -- UG TODO there is no such thing in the new api,
                    -- nor an upgrade event, which could be useful
                    local upgradedConId = game.interface.upgradeConstruction(
                        result.resultEntities[1],
                        oldCon.fileName,
                        paramsBak
                    )
                    logger.print('upgradeConstruction succeeded') logger.debugPrint(upgradedConId)
                end,
                function(error)
                    if forcedConTransf ~= nil then
                        logger.print('upgradeConstruction failed, revert failed, giving up')
                    elseif isIgnoreErrors then
                        logger.print('upgradeConstruction failed, ignoring')
                    else
                        logger.print('upgradeConstruction failed, a path has probably been broken, attempting to revert')
                        actions.moveConstruction(conId, constants.idTransf, false, true, oldConTransf)
                    end
                end
            )
        end
    )
end

return {
    handleEvent = function(src, id, name, args)
        if id ~= constants.eventId then return end

        xpcall(
            function()
                logger.print('handleEvent firing, src =', src, ', id =', id, ', name =', name, ', args =') logger.debugPrint(args)

                if name == constants.events.move_construction then
                    --[[
                        local sampleArgs = {
                            refTransf = { 0.95053715229997, -0.31061088534927, 0, 0, 0.31061088534927, 0.95053715229997, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, }, -- table
                            conId = 32148,
                            isIgnoreErrors = true,
                            traslX = -1,
                        }
                    ]]
                    local transfType = constants.transfTypes.none
                    local deltaTransf = nil
                    if args[constants.transfNames.rotX] then
                        deltaTransf = transfUtilsUG.rotX(args[constants.transfNames.rotX])
                        transfType = constants.transfTypes.rot
                    elseif args[constants.transfNames.rotY] then
                        deltaTransf = transfUtilsUG.rotY(args[constants.transfNames.rotY])
                        transfType = constants.transfTypes.rot
                    elseif args[constants.transfNames.rotZ] then
                        deltaTransf = transfUtilsUG.rotZ(args[constants.transfNames.rotZ])
                        transfType = constants.transfTypes.rot
                    elseif args[constants.transfNames.scaleX] then
                        deltaTransf = transfUtilsUG.scale({x = args[constants.transfNames.scaleX], y = 1, z = 1})
                        transfType = constants.transfTypes.scale
                    elseif args[constants.transfNames.scaleY] then
                        deltaTransf = transfUtilsUG.scale({x = 1, y = args[constants.transfNames.scaleY], z = 1})
                        transfType = constants.transfTypes.scale
                    elseif args[constants.transfNames.scaleZ] then
                        deltaTransf = transfUtilsUG.scale({x = 1, y = 1, z = args[constants.transfNames.scaleZ]})
                        transfType = constants.transfTypes.scale
                    elseif args[constants.transfNames.skewXZ] then
                        deltaTransf = transfUtils.getTransf_XSkewedOnZ(constants.idTransf, args[constants.transfNames.skewXZ])
                        transfType = constants.transfTypes.skew
                    elseif args[constants.transfNames.skewYZ] then
                        deltaTransf = transfUtils.getTransf_YSkewedOnZ(constants.idTransf, args[constants.transfNames.skewYZ])
                        transfType = constants.transfTypes.skew
                    elseif args[constants.transfNames.skewXY] then
                        deltaTransf = transfUtils.getTransf_XSkewedOnY(constants.idTransf, args[constants.transfNames.skewXY])
                        transfType = constants.transfTypes.skew
                    else
                        logger.print('args.refTransf =') logger.debugPrint(args.refTransf)
                        deltaTransf = {
                            1, 0, 0, 0,
                            0, 1, 0, 0,
                            0, 0, 1, 0,
                            (args[constants.transfNames.traslX] or 0), (args[constants.transfNames.traslY] or 0), (args[constants.transfNames.traslZ] or 0), 1
                        }
                        logger.print('deltaTransf first =') logger.debugPrint(deltaTransf)
                        deltaTransf = transfUtilsUG.mul(args.refTransf, deltaTransf)
                        logger.print('deltaTransf adjusted =') logger.debugPrint(deltaTransf)
                        deltaTransf = {
                            1, 0, 0, 0,
                            0, 1, 0, 0,
                            0, 0, 1, 0,
                            deltaTransf[13], deltaTransf[14], deltaTransf[15], 1
                        }
                        transfType = constants.transfTypes.trasl
                    end

                    logger.print('transfType = ', transfType, ', deltaTransf before moving =') logger.debugPrint(deltaTransf)
                    actions.moveConstruction(args.conId, deltaTransf, transfType, args.isIgnoreErrors)
                elseif name == constants.events.toggle_notaus then
                    logger.print('toggle_notaus fired, state before =') logger.debugPrint(stateHelpers.getState())
                    local state = stateHelpers.getState()
                    state.is_on = not(not(args))
                    logger.print('toggle_notaus fired, state after =') logger.debugPrint(stateHelpers.getState())
                end
            end,
            logger.xpErrorHandler
        )
    end,
}
