local conBlacklist = require('lolloConMover.updateOtherConstructions.conBlacklist')
local conParamBlacklist = require('lolloConMover.updateOtherConstructions.conParamBlacklist')
local conTypeWhitelist = require('lolloConMover.updateOtherConstructions.conTypeWhitelist')
local logger = require('lolloConMover.logger')
local utils = require('lolloConMover.utils')

return function (fileName, data)
    if not(data) or (type(data.updateFn) ~= 'function') then return data end

    -- whitelist constructions of certain types
    local isConTypeAllowed = false
    for _, cty in pairs(conTypeWhitelist) do
        if data.type == cty then isConTypeAllowed = true break end
    end
    if not(isConTypeAllowed) then return data end

    -- blacklist some constructions, which are known to make trouble.
    for _, gMa in pairs(conBlacklist) do
        for match in string.gmatch(fileName, gMa) do
            logger.print('loadConstructionFunc is skipping the con with fileName = ' .. tostring(fileName))
            return data
        end
    end

    -- blacklist constructions with certain parameter keys
    local conParams = data.params
    if type(conParams) == 'table' then
        local nConParams = #conParams or 0
        if nConParams > 0 then
            for i = 1, nConParams, 1 do
                local paramKey = conParams[i] and conParams[i]['key']
                if type(paramKey) == 'string' then
                    for _, gMa in pairs(conParamBlacklist) do
                        for match in string.gmatch(paramKey, gMa) do
                            logger.print('loadConstructionFunc is skipping the con with param key = ' .. tostring(paramKey) .. ' and fileName = ' .. tostring(fileName))
                            return data
                        end
                    end
                end
            end
        end
    end

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
