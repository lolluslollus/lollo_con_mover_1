
local stateHelpers = require('lolloConMover.stateHelpers')
local workerEngine = require('lolloConMover.workerEngine')
local guiEngine = require('lolloConMover.guiEngine')

-- LOLLO NOTE you can only update the state from the worker thread
stateHelpers.initState()

function data()
    return {
        save = function()
            -- only fires when the worker thread changes the state
            return stateHelpers.saveState()
        end,

        load = function(loadedstate)
            -- fires once in the worker thread, at game load, and many times in the UI thread
            stateHelpers.loadState(loadedstate)
        end,

        handleEvent = function(src, id, name, param)
            workerEngine.handleEvent(src, id, name, param)
        end,

        guiHandleEvent = function(id, name, param)
            guiEngine.handleEvent(id, name, param)
        end,

        guiInit = function()
            guiEngine.guiInit()
        end,
    }
end
