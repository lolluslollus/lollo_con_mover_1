local conBlacklist = require('lolloConMover.updateOtherConstructions.conBlacklist')
local conParamBlacklist = require('lolloConMover.updateOtherConstructions.conParamBlacklist')
local conTypeWhitelist = require('lolloConMover.updateOtherConstructions.conTypeWhitelist')
local logger = require('lolloConMover.logger')
local utils = require('lolloConMover.utils')


local funcs = {
    isConAllowed_basedOnType = function(data)
        -- logger.print('isConAllowed_basedOnType starting')
        for _, cty in pairs(conTypeWhitelist) do
            if data.type == cty then return true end
        end
        return false
    end,
    isConTypeAllowed_basedOnFileName = function(fileName)
        local conRepId = api.res.constructionRep.find(fileName)
        if conRepId < 0 then return false end

        local conProps = api.res.constructionRep.get(conRepId)
        if not(conProps) then return false end

        local conType = conProps.type
        for _, value in pairs(conTypeWhitelist) do
            if conType == api.type.enum.ConstructionType[value] then return true end
        end
        return false
    end,
    isConAllowed_basedOnFileName = function(fileName)
        -- logger.print('isConAllowed_basedOnFileName starting; fileName = ' .. tostring(fileName))
        for _, gMa in pairs(conBlacklist) do
            logger.print('gMa = ' .. tostring(gMa))
            for match in string.gmatch(fileName, gMa) do
                logger.print('skipping the con with fileName = ' .. tostring(fileName))
                return false
            end
        end
        return true
    end,
    isConAllowed_basedOnParams = function(fileName, conParams)
        -- logger.print('isConAllowed_basedOnParams starting; fileName = ' .. tostring(fileName))
        if type(conParams) == 'table' or type(conParams) == 'userdata' then
            local nConParams = #conParams or 0
            if nConParams > 0 then
                for i = 1, nConParams, 1 do
                    local paramKey = conParams[i] and conParams[i]['key']
                    if type(paramKey) == 'string' then
                        for _, gMa in pairs(conParamBlacklist) do
                            for match in string.gmatch(paramKey, gMa) do
                                logger.print('skipping the con with param key = ' .. tostring(paramKey) .. ' and fileName = ' .. tostring(fileName))
                                return false
                            end
                        end
                    end
                end
            end
        else
            return false
        end
        return true
    end,
}

funcs.loadConstructionFunc = function (fileName, data)
    if not(data) or (type(data.updateFn) ~= 'function') or type(fileName) ~= 'string' then return data end

    -- whitelist constructions of certain types
    if not(funcs.isConAllowed_basedOnType(data)) then return data end

    -- blacklist some constructions, which are known to make trouble.
    if not(funcs.isConAllowed_basedOnFileName(fileName)) then return data end

    -- blacklist constructions with certain parameter keys
    if not(funcs.isConAllowed_basedOnParams(fileName, data.params)) then return data end

    -- LOLLO TODO do we need this? We probably do with some mods. I took it out with minor 13.
    -- if type(data.upgradeFn) ~= 'function' then
    -- 	data.upgradeFn = function(_) return {} end
    -- else
    -- 	logger.print('upgradeFn() found for', fileName)
    -- end

    logger.print('loadConstructionFunc about to update con with filename = ' .. fileName .. '; data.type = ' .. tostring(data.type))

    local _originalUpdateFn = data.updateFn
    data.updateFn = function(params)
        local result = _originalUpdateFn(params)
        if not(result) then
            logger.print('no result')
            return result
        end

        logger.print('construction.updateFn starting for con with filename = ' .. fileName .. '; params.upgrade = ' .. tostring(params.upgrade) .. '; updateFn result =')
        -- logger.debugPrint(result)

        -- if not(params.upgrade) then return result end

        if not(result.edgeLists) or #result.edgeLists == 0 then
            -- if not(result.terrainAlignmentLists) then
            -- 	result.terrainAlignmentLists = utils.getDummyTerrainAlignmentLists()
            -- end
            if not(result.groundFaces) or #result.groundFaces == 0 then
                result.groundFaces = utils.getDummyGroundFaces()
                logger.print('result.groundFaces was corrected')
            end
        end

        return result
    end -- end of updateFn

    return data
end

return funcs
