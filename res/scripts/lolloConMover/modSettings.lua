local logger = require('lolloConMover.logger')
local results = {}

local function _getModSettingsFromGameConfig()
    if type(game) ~= 'table' or type(game.config) ~= 'table' then return nil end
    return game.config._lolloConMover
end

local function _getModSettingsFromApi()
    if type(api) ~= 'table' or type(api.res) ~= 'table' or type(api.res.getBaseConfig) ~= 'table' then return end

    local baseConfig = api.res.getBaseConfig()
    if not(baseConfig) then return end

    return baseConfig._lolloConMover
end

results._paramValues = {
    forceOtherCons = {
        allValues = { 0, 1 },
        defaultValueIndexBase0 = 1,
    }
}

local function _getDefaultForceOtherCons()
    return results._paramValues.forceOtherCons.allValues[results._paramValues.forceOtherCons.defaultValueIndexBase0 + 1]
end

results.getForceOtherCons = function()
    -- LOLLO NOTE try game.config first!
    local modSettings = _getModSettingsFromGameConfig() or _getModSettingsFromApi()
    if not(modSettings) then
        logger.warn('cannot read modSettings')
        return _getDefaultForceOtherCons()
    end

    logger.print('_getDefaultForceOtherCons got modSettings =') logger.debugPrint(modSettings)
    return results._paramValues.forceOtherCons.allValues[modSettings['forceOtherCons'] + 1] or _getDefaultForceOtherCons()
end

results.setModParamsFromRunFn = function(modParams)
    -- LOLLO NOTE if all default values are set, modParams in runFn will be an empty table,
    -- so thisModParams here will be nil
    -- In this case, we assign the default values.
    if type(game) ~= 'table' or type(game.config) ~= 'table' or modParams == nil then return end

    if type(game.config._lolloConMover) ~= 'table' then
        game.config._lolloConMover = {}
    end

    local thisModParams = modParams[getCurrentModId()]
    if type(thisModParams) == 'table'
    and type(thisModParams.forceOtherCons) == 'number'
    and thisModParams.forceOtherCons >= 0
    and thisModParams.forceOtherCons < #results._paramValues.forceOtherCons.allValues
    then
        game.config._lolloConMover.forceOtherCons = thisModParams.forceOtherCons -- LOLLO NOTE base 0 and base 1
    else
        game.config._lolloConMover.forceOtherCons = results._paramValues.forceOtherCons.defaultValueIndexBase0
    end

    logger.print('setModParamsFromRunFn about to return modParams =') logger.debugPrint(modParams)
    logger.print('thisModParams =') logger.debugPrint(thisModParams)
    logger.print('game.config._lolloConMover =') logger.debugPrint(game.config._lolloConMover)
end

return results
