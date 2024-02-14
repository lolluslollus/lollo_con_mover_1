local arrayUtils = require('lolloConMover.arrayUtils')
local conChooser = require('lolloConMover.conChooser')
local constants = require('lolloConMover.constants')
local logger = require ('lolloConMover.logger')
local stateHelpers = require('lolloConMover.stateHelpers')
local transfUtilsUG = require('transf')
local utils = require('lolloConMover.utils')


local _getNewRotTransf = function(oldConTransf, deltaTransf)
    -- this will rotate and translate the construction around its own axes,
    -- not around the world axes.
    local newConTransf = transfUtilsUG.mul(oldConTransf, deltaTransf)
    return newConTransf
end
local _getNewShiftTransf = function(oldConTransf, deltaTransf)
    -- this will shift the construction along the world axes
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
    moveConstruction = function(conId, deltaTransf, isRotateTransf, isIgnoreErrors, forcedConTransf)
        if not(utils.isValidAndExistingId(conId)) then
            logger.print('moveConstruction cannot shift construction with id =', conId or 'NIL', 'because it is not valid or does not exist')
            return
        end
        local oldCon = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
        if not(oldCon) then
            logger.print('moveConstruction cannot shift construction with id =', conId or 'NIL', 'because it cannot be read')
            return
        end
--[[
        if not(conChooser.isConTypeAllowed_basedOnFileName(oldCon.fileName)) then
            logger.print('moveConstruction is skipping the con with fileName = ' .. tostring(oldCon.fileName) .. ' because it is not in the whitelist')
            return
        end
        if not(conChooser.isConAllowed_basedOnFileName(oldCon.fileName)) then
            logger.print('moveConstruction is skipping the con with blacklisted fileName = ' .. tostring(oldCon.fileName))
            return
        end
        if not(conChooser.isConAllowed_basedOnParams(oldCon.fileName, oldCon.params)) then
            logger.print('moveConstruction is skipping the con with fileName = ' .. tostring(oldCon.fileName) .. ' because it has blacklisted params')
            return
        end
]]
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
        elseif isRotateTransf then
            newConTransf = _getNewRotTransf(oldConTransf, deltaTransf)
        else
            newConTransf = _getNewShiftTransf(oldConTransf, deltaTransf)
        end
        -- logger.print('newConTransf =') logger.debugPrint(newConTransf)
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
    end,
}

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
                            shiftX = -1,
                        }
                    ]]
                    local isRotateTransf = true
                    local deltaTransf = nil
                    if args[constants.transNames.rotX] then
                        deltaTransf = transfUtilsUG.rotX(args[constants.transNames.rotX])
                    elseif args[constants.transNames.rotY] then
                        deltaTransf = transfUtilsUG.rotY(args[constants.transNames.rotY])
                    elseif args[constants.transNames.rotZ] then
                        deltaTransf = transfUtilsUG.rotZ(args[constants.transNames.rotZ])
                    else
                        isRotateTransf = false
                        logger.print('args.refTransf =') logger.debugPrint(args.refTransf)
                        deltaTransf = {
                            1, 0, 0, 0,
                            0, 1, 0, 0,
                            0, 0, 1, 0,
                            (args[constants.transNames.shiftX] or 0), (args[constants.transNames.shiftY] or 0), (args[constants.transNames.shiftZ] or 0), 1
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
                    end

                    logger.print('isRotateTransf = ', isRotateTransf, ', deltaTransf before moving =') logger.debugPrint(deltaTransf)
                    actions.moveConstruction(args.conId, deltaTransf, isRotateTransf, args.isIgnoreErrors)
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
