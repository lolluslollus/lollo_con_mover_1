local constants = require('lolloConMover.constants')
local edgeUtilsDumb = require('lolloConMover.utils')
local logger = require ('lolloConMover.logger')
local transfUtilsUG = require('transf')


local _texts = {
    absoluteNWSE = _('AbsoluteNWSE'),
    conId = _('ConId'),
    fineAdjustments = _('FineAdjustments'),
    goThere = _('GoThere'),
    ignoreErrors = _('IgnoreErrors'),
    moveWindowTitle = _('MoveWindowTitle'),
    note = _('Note'),
    operationOff = _('OperationOff'),
    operationOn = _('OperationOn'),
    rotXMinus = _('RotXMinus'),
    rotXPlus = _('RotXPlus'),
    rotYMinus = _('RotYMinus'),
    rotYPlus = _('RotYPlus'),
    rotZMinus = _('RotZMinus'),
    rotZPlus = _('RotZPlus'),
    scaleXMinus = _('ScaleXMinus'),
    scaleXPlus = _('ScaleXPlus'),
    scaleYMinus = _('ScaleYMinus'),
    scaleYPlus = _('ScaleYPlus'),
    scaleZMinus = _('ScaleZMinus'),
    scaleZPlus = _('ScaleZPlus'),
    skewXZMinus = _('SkewXZMinus'),
    skewXZPlus = _('SkewXZPlus'),
    skewYZMinus = _('SkewYZMinus'),
    skewYZPlus = _('SkewYZPlus'),
    skewXYMinus = _('SkewXYMinus'),
    skewXYPlus = _('SkewXYPlus'),
    undo = _('Undo'),
    xMinus = _('West'),
    xPlus = _('East'),
    yMinus = _('South'),
    yPlus = _('North'),
    zMinus = _('Down'),
    zPlus = _('Up'),
}

local data = {
    conTransfs_indexedBy_conId = {},
    isAbsoluteNWSEOn = false,
    isFineAdjustmentsOn = false,
    isIgnoreErrorsOn = true,
    isShowingWarning = false,
    windowSizeX = 400,
    windowSizeY = 720,
}

local utils = {
    getButtonAndItsLayout = function()
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        local button = api.gui.comp.Button.new(buttonLayout, true)
        return button, buttonLayout
    end,
    getConstructionPosition = function(conId)
        if not(edgeUtilsDumb.isValidAndExistingId(conId)) then return end

        local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
        if not(con) or not(con.transf) then return end

        local conTransf = transfUtilsUG.new(con.transf:cols(0), con.transf:cols(1), con.transf:cols(2), con.transf:cols(3))
        return {
            [1] = conTransf[13],
            [2] = conTransf[14],
            [3] = conTransf[15]
        }
    end,
    getConstructionTransf = function(conId)
        if not(edgeUtilsDumb.isValidAndExistingId(conId)) then return end

        local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
        if not(con) or not(con.transf) then return end

        return transfUtilsUG.new(con.transf:cols(0), con.transf:cols(1), con.transf:cols(2), con.transf:cols(3))
    end,
    getLinearShift = function()
        return data.isFineAdjustmentsOn and constants.smallLinearShift or constants.bigLinearShift
    end,
    getRotShift = function()
        return data.isFineAdjustmentsOn and constants.smallRotShift or constants.bigRotShift
    end,
    getScaleShift = function()
        return data.isFineAdjustmentsOn and constants.smallScaleShift or constants.bigScaleShift
    end,
    getSkewShift = function()
        return data.isFineAdjustmentsOn and constants.smallSkewShift or constants.bigSkewShift
    end,
    modifyOnOffButtonLayout = function(layout, isOn, text)
        if isOn then
            layout:addItem(api.gui.comp.ImageView.new('ui/design/components/checkbox_valid.tga'), api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
        else
            layout:addItem(api.gui.comp.ImageView.new('ui/design/components/checkbox_invalid.tga'), api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
        end
        layout:addItem(api.gui.comp.TextView.new(text), api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
    end,
    modifyOnOffButtonLayout2 = function(layout, isOn)
        local img = nil
        if isOn then
            -- img = api.gui.comp.ImageView.new('ui/design/components/checkbox_valid.tga')
            img = api.gui.comp.ImageView.new('ui/lolloConMover/checkbox_valid.tga')
            img:setTooltip(_texts.operationOn)
            layout:addItem(img, api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
            -- layout:addItem(api.gui.comp.TextView.new(_texts.operationOn), api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
        else
            -- img = api.gui.comp.ImageView.new('ui/design/components/checkbox_invalid.tga')
            img = api.gui.comp.ImageView.new('ui/lolloConMover/checkbox_invalid.tga')
            img:setTooltip(_texts.operationOff)
            layout:addItem(img, api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
            -- layout:addItem(api.gui.comp.TextView.new(_texts.operationOff), api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
        end
    end,
    moveCamera = function(position)
        local cameraData = game.gui.getCamera()
        -- posX, posY, distance, rotZ (not normalised), tanZ (max = 1)
        game.gui.setCamera({position[1], position[2], cameraData[3], cameraData[4], cameraData[5]})
    end,
    ---position window keeping it within the screen
    ---@param window any
    ---@param initialPosition {x:number, y:number}|nil
    setWindowPosition = function(window, initialPosition)
        local gameContentRect = api.gui.util.getGameUI():getContentRect()
        local windowContentRect = window:getContentRect()
        local windowMinimumSize = window:calcMinimumSize()

        local windowHeight = math.max(windowContentRect.h, windowMinimumSize.h)
        local windowWidth = math.max(windowContentRect.w, windowMinimumSize.w)
        local positionX = (initialPosition ~= nil and initialPosition.x) or math.max(0, (gameContentRect.w - windowWidth) * 0.5)
        -- local positionY = (initialPosition ~= nil and initialPosition.y) or math.max(0, (gameContentRect.h - windowHeight) * 0.5)
        local positionY = (initialPosition ~= nil and initialPosition.y) or 50

        if (positionX + windowWidth) > gameContentRect.w then
            positionX = math.max(0, gameContentRect.w - windowWidth)
        end
        if (positionY + windowHeight) > gameContentRect.h then
            positionY = math.max(0, gameContentRect.h - windowHeight -100)
        end

        window:setPosition(math.floor(positionX), math.floor(positionY))
    end
}
utils.undoBuffer = {
    ---removes non existing objects from buffer - it does not check if they are constructions or something else
    clean = function()
        logger.print('data.conTransfs_indexedBy_conId before =') logger.debugPrint(data.conTransfs_indexedBy_conId)
        for conId, transf in pairs(data.conTransfs_indexedBy_conId) do
            if not edgeUtilsDumb.isValidAndExistingId(conId) then
                data.conTransfs_indexedBy_conId[conId] = nil
            end
        end
        logger.print('data.conTransfs_indexedBy_conId after =') logger.debugPrint(data.conTransfs_indexedBy_conId)
    end,
    ---returns nil or the buffered con transf
    ---@param conId integer
    ---@return table<number>|nil
    get = function(conId)
        if not(conId) then return nil end
        return data.conTransfs_indexedBy_conId[conId]
    end,
    ---adds a construction to the buffer, returns nil or the current con transf
    ---@param conId integer
    ---@return table<number>|nil
    init = function(conId)
        local conTransf = utils.getConstructionTransf(conId)
        if not(conTransf) then return nil end

        if not(data.conTransfs_indexedBy_conId[conId]) then
            logger.print('init undo buffer for conId ' .. tostring(conId))
            data.conTransfs_indexedBy_conId[conId] = conTransf
        end

        return conTransf
    end,
    ---removes a construction from the buffer
    ---@param conId any
    remove = function(conId)
        if not(conId) or not(data.conTransfs_indexedBy_conId[conId]) then return end
        data.conTransfs_indexedBy_conId[conId] = nil
    end,
    ---what it says
    ---@param isEnabled any
    setUndoButtonEnabled = function(isEnabled)
        local button = api.gui.util.getById(constants.guiIds.undoButton)
        if not(button) then return end

        local isExit = false
        while not(isExit) do
            local buttonContent = button:getLayout():getItem(0)
            if not(buttonContent) then
                isExit = true
            else
                button:getLayout():removeItem(buttonContent)
            end
        end
        if not(isEnabled) then
            button:setEnabled(false)
            button:getLayout():addItem(api.gui.comp.ImageView.new('ui/lolloConMover/undo_disabled.tga'), api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
        else
            button:setEnabled(true)
            button:getLayout():addItem(api.gui.comp.ImageView.new('ui/lolloConMover/undo_enabled.tga'), api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
        end
    end
}
---removes a construction from the buffer and disables the undo button of its window - it uses the window name to match windows to constructions
---@param conId integer
utils.undoBuffer.removeCon = function(conId)
    utils.undoBuffer.remove(conId)

    local window = api.gui.util.getById(constants.guiIds.moveWindow)
    if not(window) or window:getName() ~= tostring(conId) then return end

    utils.undoBuffer.setUndoButtonEnabled(false)
end

return {
    ---brings up the move window
    ---@param conId integer
    ---@param callback showMoveWindowCallback
    showMoveWindow = function(conId, callback)
        local conTransf = utils.undoBuffer.init(conId)

        local layout = api.gui.layout.AbsoluteLayout.new()
        local window = api.gui.util.getById(constants.guiIds.moveWindow)
        local windowTitle = _texts.moveWindowTitle .. ' - ' .. _texts.conId .. tostring(conId)
        if window == nil then
            logger.print('showMoveWindow starting, creating the window')
            window = api.gui.comp.Window.new(windowTitle, layout)
            window:setId(constants.guiIds.moveWindow)
            window:setName(tostring(conId))
            window:setSize(api.gui.util.Size.new(data.windowSizeX, data.windowSizeY))
        else
            logger.print('showMoveWindow starting, window exists')
            window:setTitle(windowTitle)
            window:setContent(layout)
            window:setName(tostring(conId))
            window:setVisible(true, false)
        end
        window:setResizable(true)
        -- window:setHighlighted(true)

        utils.setWindowPosition(window, {x = 100})

        window:addHideOnCloseHandler()

        local _y0 = 15

        local function addInfoIcon()
            local infoIcon = api.gui.comp.ImageView.new('ui/button/medium/info.tga')
            infoIcon:setTooltip(_texts.note)
            layout:addItem(infoIcon, api.gui.util.Rect.new(160, _y0 + 0, 40, 40))
        end
        local function addUndoButton()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/undo_disabled.tga'))
            button:setTooltip(_texts.undo)
            button:setId(constants.guiIds.undoButton)
            logger.print('utils.undoBuffer.get(conId) =') logger.debugPrint(utils.undoBuffer.get(conId))

            local bufferConTransf = utils.undoBuffer.get(conId)
            local isEnableUndo = type(bufferConTransf) == 'table' and type(conTransf) == 'table'
            if isEnableUndo then
                isEnableUndo = false
                for i = 1, 16, 1 do
---@diagnostic disable-next-line: need-check-nil
                    if bufferConTransf[i] ~= conTransf[i] then
                        isEnableUndo = true
                        break
                    end
                end
            end
            utils.undoBuffer.setUndoButtonEnabled(isEnableUndo)
            button:onClick(
                function()
                    if not callback(constants.transfNames.undo, 0, data.isIgnoreErrorsOn, data.isAbsoluteNWSEOn, bufferConTransf)
                    then utils.undoBuffer.removeCon(conId)
                    else utils.undoBuffer.setUndoButtonEnabled(false)
                    end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(165, _y0 + 40, 40, 40))
        end
        local function addGotoButton()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/locate.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.goThere))
            button:onClick(
                function()
                    local pos = utils.getConstructionPosition(conId)
                    if not(pos) then return end

                    utils.moveCamera(pos)
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(0, _y0, 100, 40))
        end
        local function addAbsoluteNWSEToggleButton()
            local toggleButtonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
            utils.modifyOnOffButtonLayout(toggleButtonLayout, data.isAbsoluteNWSEOn, _texts.absoluteNWSE)
            local toggleButton = api.gui.comp.ToggleButton.new(toggleButtonLayout)
            toggleButton:setSelected(data.isAbsoluteNWSEOn, false)
            toggleButton:onToggle(function(isOn) -- isOn is boolean
                -- logger.print('isAbsoluteNWSEOn toggled; isOn = ', isOn)
                while toggleButtonLayout:getNumItems() > 0 do
                    local item0 = toggleButtonLayout:getItem(0)
                    toggleButtonLayout:removeItem(item0)
                end

                for _, id in pairs(constants.guiIds.cameraIcons) do
                    local icon = api.gui.util.getById(id)
                    if icon ~= nil then icon:setVisible(not(isOn), false) end
                end

                utils.modifyOnOffButtonLayout(toggleButtonLayout, isOn, _texts.absoluteNWSE)
                toggleButton:setSelected(isOn, false)
                data.isAbsoluteNWSEOn = isOn
            end)
            layout:addItem(toggleButton, api.gui.util.Rect.new(230, _y0, 100, 40))
        end
        local function addIgnoreErrorsToggleButton()
            local toggleButtonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
            utils.modifyOnOffButtonLayout(toggleButtonLayout, data.isIgnoreErrorsOn, _texts.ignoreErrors)
            local toggleButton = api.gui.comp.ToggleButton.new(toggleButtonLayout)
            toggleButton:setSelected(data.isIgnoreErrorsOn, false)
            toggleButton:onToggle(function(isOn) -- isOn is boolean
                -- logger.print('isIgnoreErrorsOn toggled; isOn = ', isOn)
                while toggleButtonLayout:getNumItems() > 0 do
                    local item0 = toggleButtonLayout:getItem(0)
                    toggleButtonLayout:removeItem(item0)
                end
                utils.modifyOnOffButtonLayout(toggleButtonLayout, isOn, _texts.ignoreErrors)
                toggleButton:setSelected(isOn, false)
                data.isIgnoreErrorsOn = isOn
            end)
            layout:addItem(toggleButton, api.gui.util.Rect.new(10, _y0 + 40, 100, 40))
        end
        local function addFineAdjustmentsToggleButton()
            local toggleButtonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
            utils.modifyOnOffButtonLayout(toggleButtonLayout, data.isFineAdjustmentsOn, _texts.fineAdjustments)
            local toggleButton = api.gui.comp.ToggleButton.new(toggleButtonLayout)
            toggleButton:setSelected(data.isFineAdjustmentsOn, false)
            toggleButton:onToggle(function(isOn) -- isOn is boolean
                -- logger.print('isFineAdjustments toggled; isOn = ', isOn)
                while toggleButtonLayout:getNumItems() > 0 do
                    local item0 = toggleButtonLayout:getItem(0)
                    toggleButtonLayout:removeItem(item0)
                end
                utils.modifyOnOffButtonLayout(toggleButtonLayout, isOn, _texts.fineAdjustments)
                toggleButton:setSelected(isOn, false)
                data.isFineAdjustmentsOn = isOn
            end)
            layout:addItem(toggleButton, api.gui.util.Rect.new(230, _y0 + 40, 100, 40))
        end
        local function addXMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_left.tga'))

            local cameraIcon = api.gui.comp.ImageView.new('ui/icons/windows/camera.tga')
            cameraIcon:setId(constants.guiIds.cameraIcons.west)
            cameraIcon:setVisible(not(data.isAbsoluteNWSEOn), false)
            buttonLayout:addItem(cameraIcon)

            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.xMinus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.traslX, -utils.getLinearShift(), data.isIgnoreErrorsOn, data.isAbsoluteNWSEOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 140, 100, 40))
        end
        local function addXPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_right.tga'))

            local cameraIcon = api.gui.comp.ImageView.new('ui/icons/windows/camera.tga')
            cameraIcon:setId(constants.guiIds.cameraIcons.east)
            cameraIcon:setVisible(not(data.isAbsoluteNWSEOn), false)
            buttonLayout:addItem(cameraIcon)

            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.xPlus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.traslX, utils.getLinearShift(), data.isIgnoreErrorsOn, data.isAbsoluteNWSEOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 140, 100, 40))
        end
        local function addYMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_down.tga'))

            local cameraIcon = api.gui.comp.ImageView.new('ui/icons/windows/camera.tga')
            cameraIcon:setId(constants.guiIds.cameraIcons.south)
            cameraIcon:setVisible(not(data.isAbsoluteNWSEOn), false)
            buttonLayout:addItem(cameraIcon)

            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.yMinus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.traslY, -utils.getLinearShift(), data.isIgnoreErrorsOn, data.isAbsoluteNWSEOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(100, _y0 + 180, 100, 40))
        end
        local function addYPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_up.tga'))

            local cameraIcon = api.gui.comp.ImageView.new('ui/icons/windows/camera.tga')
            cameraIcon:setId(constants.guiIds.cameraIcons.north)
            cameraIcon:setVisible(not(data.isAbsoluteNWSEOn), false)
            buttonLayout:addItem(cameraIcon)

            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.yPlus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.traslY, utils.getLinearShift(), data.isIgnoreErrorsOn, data.isAbsoluteNWSEOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(100, _y0 + 100, 100, 40))
        end
        local function addZMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_down.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.zMinus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.traslZ, -utils.getLinearShift(), data.isIgnoreErrorsOn, data.isAbsoluteNWSEOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(300, _y0 + 180, 100, 40))
        end
        local function addZPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_up.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.zPlus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.traslZ, utils.getLinearShift(), data.isIgnoreErrorsOn, data.isAbsoluteNWSEOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(300, _y0 + 100, 100, 40))
        end
        local function addRotXMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/rotate_clockwise.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotXMinus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.rotX, -utils.getRotShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 240, 100, 40))
        end
        local function addRotXPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/rotate_anticlockwise.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotXPlus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.rotX, utils.getRotShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 240, 100, 40))
        end
        local function addRotYMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/rotate_clockwise.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotYMinus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.rotY, -utils.getRotShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 280, 100, 40))
        end
        local function addRotYPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/rotate_anticlockwise.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotYPlus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.rotY, utils.getRotShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 280, 100, 40))
        end
        local function addRotZMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/rotate_clockwise.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotZMinus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.rotZ, -utils.getRotShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 320, 100, 40))
        end
        local function addRotZPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/rotate_anticlockwise.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotZPlus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.rotZ, utils.getRotShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 320, 100, 40))
        end
        local function addScaleXMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/scale_minus.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.scaleXMinus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.scaleX, 1 / utils.getScaleShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 380, 100, 40))
        end
        local function addScaleXPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/scale_plus.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.scaleXPlus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.scaleX, utils.getScaleShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 380, 100, 40))
        end
        local function addScaleYMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/scale_minus.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.scaleYMinus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.scaleY, 1 / utils.getScaleShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 420, 100, 40))
        end
        local function addScaleYPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/scale_plus.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.scaleYPlus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.scaleY, utils.getScaleShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 420, 100, 40))
        end
        local function addScaleZMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/scale_minus.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.scaleZMinus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.scaleZ, 1 / utils.getScaleShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 460, 100, 40))
        end
        local function addScaleZPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/scale_plus.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.scaleZPlus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.scaleZ, utils.getScaleShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 460, 100, 40))
        end
        local function addSkewXZMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/skew_minus.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.skewXZMinus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.skewXZ, -utils.getSkewShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 520, 100, 40))
        end
        local function addSkewXZPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/skew_plus.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.skewXZPlus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.skewXZ, utils.getSkewShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 520, 100, 40))
        end
        local function addSkewYZMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/skew_minus.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.skewYZMinus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.skewYZ, -utils.getSkewShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 560, 100, 40))
        end
        local function addSkewYZPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/skew_plus.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.skewYZPlus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.skewYZ, utils.getSkewShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 560, 100, 40))
        end
        local function addSkewXYMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/skew_minus.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.skewXYMinus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.skewXY, -utils.getSkewShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 600, 100, 40))
        end
        local function addSkewXYPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/skew_plus.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.skewXYPlus))
            button:onClick(
                function()
                    if not callback(constants.transfNames.skewXY, utils.getSkewShift(), data.isIgnoreErrorsOn)
                    then utils.undoBuffer.removeCon(conId) else utils.undoBuffer.setUndoButtonEnabled(true) end
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 600, 100, 40))
        end

        addInfoIcon()
        addUndoButton()
        addGotoButton()
        addAbsoluteNWSEToggleButton()
        addIgnoreErrorsToggleButton()
        addFineAdjustmentsToggleButton()
        addXMinus1Button()
        addXPlus1Button()
        addYMinus1Button()
        addYPlus1Button()
        addZMinus1Button()
        addZPlus1Button()
        addRotXMinus1Button()
        addRotXPlus1Button()
        addRotYMinus1Button()
        addRotYPlus1Button()
        addRotZMinus1Button()
        addRotZPlus1Button()
        addScaleXMinus1Button()
        addScaleXPlus1Button()
        addScaleYMinus1Button()
        addScaleYPlus1Button()
        addScaleZMinus1Button()
        addScaleZPlus1Button()
        addSkewXZMinus1Button()
        addSkewXZPlus1Button()
        addSkewYZMinus1Button()
        addSkewYZPlus1Button()
        addSkewXYMinus1Button()
        addSkewXYPlus1Button()
    end,

    showWarningWindowWithMessage = function(text)
        data.isShowingWarning = true
        local layout = api.gui.layout.BoxLayout.new('VERTICAL')
        local window = api.gui.util.getById(constants.guiIds.warningWindowWithMessage)
        if window == nil then
            window = api.gui.comp.Window.new(_texts.moveWindowTitle, layout)
            window:setId(constants.guiIds.warningWindowWithMessage)
        else
            window:setContent(layout)
            window:setVisible(true, false)
        end

        layout:addItem(api.gui.comp.TextView.new(text))

        window:setHighlighted(true)
        local position = api.gui.util.getMouseScreenPos()
        window:setPosition(position.x -200, position.y)
        -- window:addHideOnCloseHandler()
        window:onClose(
            function()
                window:setVisible(false, false)
            end
        )
    end,

    initNotausToggleButton = function(isFunctionOn, funcOfBool)
        if api.gui.util.getById(constants.guiIds.operationOnOffButton) then return end

        local toggleButtonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        utils.modifyOnOffButtonLayout2(toggleButtonLayout, isFunctionOn)
        local toggleButton = api.gui.comp.ToggleButton.new(toggleButtonLayout)
        toggleButton:setSelected(isFunctionOn, false)
        toggleButton:onToggle(function(isOn) -- isOn is boolean
            -- logger.print('isFunctionOn toggled; isOn = ', isOn)
            while toggleButtonLayout:getNumItems() > 0 do
                local item0 = toggleButtonLayout:getItem(0)
                toggleButtonLayout:removeItem(item0)
            end
            utils.modifyOnOffButtonLayout2(toggleButtonLayout, isOn)
            toggleButton:setSelected(isOn, false)
            funcOfBool(isOn)
        end)

        toggleButton:setId(constants.guiIds.operationOnOffButton)

        api.gui.util.getById('gameInfo'):getLayout():addItem(toggleButton)
    end,
}
