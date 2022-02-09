local utils = {}

utils.isValidId = function(id)
    return type(id) == 'number' and id > 0
end

utils.isValidAndExistingId = function(id)
    return utils.isValidId(id) and api.engine.entityExists(id)
end

return utils
