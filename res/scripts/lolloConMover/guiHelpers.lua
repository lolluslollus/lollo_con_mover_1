local constants = require('lolloConMover.constants')
local edgeUtilsDumb = require('lolloConMover.utils')
local logger = require ('lolloConMover.logger')
local transfUtilsUG = require('transf')


local _texts = {
    conId = _('ConId'),
    fineAdjustments = _('FineAdjustments'),
    goThere = _('GoThere'),
    ignoreErrors = _('IgnoreErrors'),
    operationOff = _('OperationOff'),
    operationOn = _('OperationOn'),
    rotXMinus = _('RotXMinus'),
    rotXPlus = _('RotXPlus'),
    rotYMinus = _('RotYMinus'),
    rotYPlus = _('RotYPlus'),
    rotZMinus = _('RotZMinus'),
    rotZPlus = _('RotZPlus'),
    shiftWindowTitle = _('ShiftWindowTitle'),
    xMinus = _('West'),
    xPlus = _('East'),
    yMinus = _('South'),
    yPlus = _('North'),
    zMinus = _('Down'),
    zPlus = _('Up'),
}

local data = {
    isFineAdjustmentsOn = false,
    isIgnoreErrorsOn = true,
    isShowingWarning = false,
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
    getLinearShift = function()
        return data.isFineAdjustmentsOn and constants.smallLinearShift or constants.bigLinearShift
    end,
    getRotShift = function()
        return data.isFineAdjustmentsOn and constants.smallRotShift or constants.bigRotShift
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
}

return {
    showShiftWindow = function(conId, callback)
        local layout = api.gui.layout.AbsoluteLayout.new()
        local window = api.gui.util.getById(constants.guiIds.shiftWindow)
        if window == nil then
            window = api.gui.comp.Window.new(_texts.shiftWindowTitle, layout)
            window:setId(constants.guiIds.shiftWindow)
            window:setSize(api.gui.util.Size.new(360, 360))
        else
            window:setContent(layout)
            window:setVisible(true, false)
        end
        window:setResizable(true)
        -- window:setHighlighted(true)
        -- local position = api.gui.util.getMouseScreenPos()
        -- window:setPosition(position.x + constants.windowXShift, position.y + constants.windowYShift)
        window:setGravity(4, 0) -- LOLLO TODO check this
        window:addHideOnCloseHandler()

        local _y0 = 15

        local descriptiveText = _texts.conId .. tostring(conId)
        layout:addItem(api.gui.comp.TextView.new(descriptiveText), api.gui.util.Rect.new(240, _y0, 100, 40))

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
            layout:addItem(toggleButton, api.gui.util.Rect.new(190, _y0 + 40, 100, 40))
        end
        local function addXMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_left.tga'))
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/icons/windows/camera.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.xMinus))
            button:onClick(
                function()
                    callback(constants.transNames.shiftX, -utils.getLinearShift(), data.isIgnoreErrorsOn)
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 120, 100, 40))
        end
        local function addXPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_right.tga'))
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/icons/windows/camera.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.xPlus))
            button:onClick(
                function()
                    callback(constants.transNames.shiftX, utils.getLinearShift(), data.isIgnoreErrorsOn)
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 120, 100, 40))
        end
        local function addYMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_down.tga'))
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/icons/windows/camera.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.yMinus))
            button:onClick(
                function()
                    callback(constants.transNames.shiftY, -utils.getLinearShift(), data.isIgnoreErrorsOn)
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(100, _y0 + 160, 100, 40))
        end
        local function addYPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_up.tga'))
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/icons/windows/camera.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.yPlus))
            button:onClick(
                function()
                    callback(constants.transNames.shiftY, utils.getLinearShift(), data.isIgnoreErrorsOn)
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(100, _y0 + 80, 100, 40))
        end
        local function addZMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_down.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.zMinus))
            button:onClick(
                function()
                    callback(constants.transNames.shiftZ, -utils.getLinearShift(), data.isIgnoreErrorsOn)
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(280, _y0 + 160, 100, 40))
        end
        local function addZPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_up.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.zPlus))
            button:onClick(
                function()
                    callback(constants.transNames.shiftZ, utils.getLinearShift(), data.isIgnoreErrorsOn)
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(280, _y0 + 80, 100, 40))
        end
        local function addRotXMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/rotate_clockwise.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotXMinus))
            button:onClick(
                function()
                    callback(constants.transNames.rotX, -utils.getRotShift(), data.isIgnoreErrorsOn)
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 200, 100, 40))
        end
        local function addRotXPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/rotate_anticlockwise.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotXPlus))
            button:onClick(
                function()
                    callback(constants.transNames.rotX, utils.getRotShift(), data.isIgnoreErrorsOn)
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 200, 100, 40))
        end
        local function addRotYMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/rotate_clockwise.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotYMinus))
            button:onClick(
                function()
                    callback(constants.transNames.rotY, -utils.getRotShift(), data.isIgnoreErrorsOn)
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 240, 100, 40))
        end
        local function addRotYPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/rotate_anticlockwise.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotYPlus))
            button:onClick(
                function()
                    callback(constants.transNames.rotY, utils.getRotShift(), data.isIgnoreErrorsOn)
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 240, 100, 40))
        end
        local function addRotZMinus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/rotate_clockwise.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotZMinus))
            button:onClick(
                function()
                    callback(constants.transNames.rotZ, -utils.getRotShift(), data.isIgnoreErrorsOn)
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 280, 100, 40))
        end
        local function addRotZPlus1Button()
            local button, buttonLayout = utils.getButtonAndItsLayout()
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/lolloConMover/rotate_anticlockwise.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotZPlus))
            button:onClick(
                function()
                    callback(constants.transNames.rotZ, utils.getRotShift(), data.isIgnoreErrorsOn)
                end
            )
            layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 280, 100, 40))
        end
        addGotoButton()
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
    end,

    showWarningWindowWithMessage = function(text)
        data.isShowingWarning = true
        local layout = api.gui.layout.BoxLayout.new('VERTICAL')
        local window = api.gui.util.getById(constants.guiIds.warningWindowWithMessage)
        if window == nil then
            window = api.gui.comp.Window.new(_texts.shiftWindowTitle, layout)
            window:setId(constants.guiIds.warningWindowWithMessage)
        else
            window:setContent(layout)
            window:setVisible(true, false)
        end

        layout:addItem(api.gui.comp.TextView.new(text))

        window:setHighlighted(true)
        local position = api.gui.util.getMouseScreenPos()
        window:setPosition(position.x + constants.windowXShift, position.y)
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
