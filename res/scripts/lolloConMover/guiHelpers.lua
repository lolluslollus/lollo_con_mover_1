local constants = require('lolloConMover.constants')
local edgeUtils = require('lolloConMover.edgeUtils')
local stringUtils = require('lolloConMover.stringUtils')
local transfUtilsUG = require('transf')

local _operationOnOffButtonId = 'lollo_con_mover_on_off_button'
local _shiftWindowId = 'lollo_con_mover_shift_window'
local _warningWindowWithMessageId = 'lollo_con_mover_warning_window_with_message'
local _warningWindowWithStateId = 'lollo_con_mover_warning_window_with_state'

local _texts = {
    conId = _('ConId'),
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
    xMinus = _('East'),
    xPlus = _('West'),
    yMinus = _('South'),
    yPlus = _('North'),
    zMinus = _('Down'),
    zPlus = _('Up'),
}

local _windowXShift = -200
local _windowYShift = -50

local guiHelpers = {
    getConstructionPosition = function(conId)
        if not(edgeUtils.isValidAndExistingId(conId)) then return end

        local con = api.engine.getComponent(26391, api.type.ComponentType.CONSTRUCTION)
        if not(con) or not(con.transf) then return end

        local conTransf = transfUtilsUG.new(con.transf:cols(0), con.transf:cols(1), con.transf:cols(2), con.transf:cols(3))
        return {
            [1] = conTransf[13],
            [2] = conTransf[14],
            [3] = conTransf[15]
        }
    end,
    _bigLinearShift = 1.0, -- 1 metre
    _bigRotShift = math.pi / 16, -- like in the game with <m> and <n>
    isFineAdjustmentsOn = false,
    isIgnoreErrorsOn = true,
    isShowingWarning = false,
    moveCamera = function(position)
        local cameraData = game.gui.getCamera()
        game.gui.setCamera({position[1], position[2], cameraData[3], cameraData[4], cameraData[5]})
    end,
    smallLinearShift = 0.1,
}

local _modifyIgnoreErrorsOnOffButtonLayout = function(layout)
    if guiHelpers.isIgnoreErrorsOn then
        layout:addItem(api.gui.comp.ImageView.new('ui/design/components/checkbox_valid.tga'), api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
    else
        layout:addItem(api.gui.comp.ImageView.new('ui/design/components/checkbox_invalid.tga'), api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
    end
    layout:addItem(api.gui.comp.TextView.new(_texts.ignoreErrors), api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
end

guiHelpers.showShiftWindow = function(conId, funcOfStringAndFloat)
    local layout = api.gui.layout.AbsoluteLayout.new()
    local window = api.gui.util.getById(_shiftWindowId)
    if window == nil then
        window = api.gui.comp.Window.new(_texts.shiftWindowTitle, layout)
        window:setId(_shiftWindowId)
    else
        window:setContent(layout)
        window:setVisible(true, false)
    end

    -- window:setResizable(true)
    window:setSize(api.gui.util.Size.new(360, 360))

    local _y0 = 15

    local descriptiveText = _texts.conId .. tostring(conId)
    layout:addItem(api.gui.comp.TextView.new(descriptiveText), api.gui.util.Rect.new(240, _y0, 100, 40))

    local function addGotoButton()
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/locate.tga'))
        buttonLayout:addItem(api.gui.comp.TextView.new(_texts.goThere))
        local button = api.gui.comp.Button.new(buttonLayout, true)
        button:onClick(
            function()
                edgeUtils.getObjectPosition(conId)
                local pos = guiHelpers.getConstructionPosition(conId)
                if not(pos) then return end

                guiHelpers.moveCamera(pos)
            end
        )
        layout:addItem(button, api.gui.util.Rect.new(0, _y0, 100, 40))
    end
    local function addIgnoreErrorsButton()
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        _modifyIgnoreErrorsOnOffButtonLayout(buttonLayout)
        local button = api.gui.comp.ToggleButton.new(buttonLayout)
        button:setSelected(guiHelpers.isIgnoreErrorsOn, false)
        button:onToggle(function(isOn) -- isOn is boolean
            print('toggled; isOn = ', isOn)
            while buttonLayout:getNumItems() > 0 do
                local item0 = buttonLayout:getItem(0)
                buttonLayout:removeItem(item0)
            end
            _modifyIgnoreErrorsOnOffButtonLayout(buttonLayout)
            button:setSelected(isOn, false)
            guiHelpers.isIgnoreErrorsOn = isOn
        end)
        layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 40, 100, 40))
    end
    local function addXMinus1Button(shift)
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_left.tga'))
        buttonLayout:addItem(api.gui.comp.TextView.new(_texts.xMinus))
        local button = api.gui.comp.Button.new(buttonLayout, true)
        button:onClick(
            function()
                funcOfStringAndFloat(constants.transNames.xShift, -shift, guiHelpers.isIgnoreErrorsOn)
            end
        )
        layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 120, 100, 40))
    end
    local function addXPlus1Button(shift)
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_right.tga'))
        buttonLayout:addItem(api.gui.comp.TextView.new(_texts.xPlus))
        local button = api.gui.comp.Button.new(buttonLayout, true)
        button:onClick(
            function()
                funcOfStringAndFloat(constants.transNames.xShift, shift, guiHelpers.isIgnoreErrorsOn)
            end
        )
        layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 120, 100, 40))
    end
    local function addYMinus1Button(shift)
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_down.tga'))
        buttonLayout:addItem(api.gui.comp.TextView.new(_texts.yMinus))
        local button = api.gui.comp.Button.new(buttonLayout, true)
        button:onClick(
            function()
                funcOfStringAndFloat(constants.transNames.yShift, -shift, guiHelpers.isIgnoreErrorsOn)
            end
        )
        layout:addItem(button, api.gui.util.Rect.new(100, _y0 + 160, 100, 40))
    end
    local function addYPlus1Button(shift)
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_up.tga'))
        buttonLayout:addItem(api.gui.comp.TextView.new(_texts.yPlus))
        local button = api.gui.comp.Button.new(buttonLayout, true)
        button:onClick(
            function()
                funcOfStringAndFloat(constants.transNames.yShift, shift, guiHelpers.isIgnoreErrorsOn)
            end
        )
        layout:addItem(button, api.gui.util.Rect.new(100, _y0 + 80, 100, 40))
    end
    local function addZMinus1Button(shift)
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_down.tga'))
        buttonLayout:addItem(api.gui.comp.TextView.new(_texts.zMinus))
        local button = api.gui.comp.Button.new(buttonLayout, true)
        button:onClick(
            function()
                funcOfStringAndFloat(constants.transNames.zShift, -shift, guiHelpers.isIgnoreErrorsOn)
            end
        )
        layout:addItem(button, api.gui.util.Rect.new(280, _y0 + 160, 100, 40))
    end
    local function addZPlus1Button(shift)
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_up.tga'))
        buttonLayout:addItem(api.gui.comp.TextView.new(_texts.zPlus))
        local button = api.gui.comp.Button.new(buttonLayout, true)
        button:onClick(
            function()
                funcOfStringAndFloat(constants.transNames.zShift, shift, guiHelpers.isIgnoreErrorsOn)
            end
        )
        layout:addItem(button, api.gui.util.Rect.new(280, _y0 + 80, 100, 40))
    end
    local function addRotXMinus1Button(shift)
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        buttonLayout:addItem(api.gui.comp.ImageView.new('lolloConMover/rotate_clockwise.tga'))
        buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotXMinus))
        local button = api.gui.comp.Button.new(buttonLayout, true)
        button:onClick(
            function()
                funcOfStringAndFloat(constants.transNames.rotX, -shift, guiHelpers.isIgnoreErrorsOn)
            end
        )
        layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 200, 100, 40))
    end
    local function addRotXPlus1Button(shift)
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        buttonLayout:addItem(api.gui.comp.ImageView.new('lolloConMover/rotate_anticlockwise.tga'))
        buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotXPlus))
        local button = api.gui.comp.Button.new(buttonLayout, true)
        button:onClick(
            function()
                funcOfStringAndFloat(constants.transNames.rotX, shift, guiHelpers.isIgnoreErrorsOn)
            end
        )
        layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 200, 100, 40))
    end
    local function addRotYMinus1Button(shift)
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        buttonLayout:addItem(api.gui.comp.ImageView.new('lolloConMover/rotate_clockwise.tga'))
        buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotYMinus))
        local button = api.gui.comp.Button.new(buttonLayout, true)
        button:onClick(
            function()
                funcOfStringAndFloat(constants.transNames.rotY, -shift, guiHelpers.isIgnoreErrorsOn)
            end
        )
        layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 240, 100, 40))
    end
    local function addRotYPlus1Button(shift)
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        buttonLayout:addItem(api.gui.comp.ImageView.new('lolloConMover/rotate_anticlockwise.tga'))
        buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotYPlus))
        local button = api.gui.comp.Button.new(buttonLayout, true)
        button:onClick(
            function()
                funcOfStringAndFloat(constants.transNames.rotY, shift, guiHelpers.isIgnoreErrorsOn)
            end
        )
        layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 240, 100, 40))
    end
    local function addRotZMinus1Button(shift)
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        buttonLayout:addItem(api.gui.comp.ImageView.new('lolloConMover/rotate_clockwise.tga'))
        buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotZMinus))
        local button = api.gui.comp.Button.new(buttonLayout, true)
        button:onClick(
            function()
                funcOfStringAndFloat(constants.transNames.rotZ, -shift, guiHelpers.isIgnoreErrorsOn)
            end
        )
        layout:addItem(button, api.gui.util.Rect.new(10, _y0 + 280, 100, 40))
    end
    local function addRotZPlus1Button(shift)
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        buttonLayout:addItem(api.gui.comp.ImageView.new('lolloConMover/rotate_anticlockwise.tga'))
        buttonLayout:addItem(api.gui.comp.TextView.new(_texts.rotZPlus))
        local button = api.gui.comp.Button.new(buttonLayout, true)
        button:onClick(
            function()
                funcOfStringAndFloat(constants.transNames.rotZ, shift, guiHelpers.isIgnoreErrorsOn)
            end
        )
        layout:addItem(button, api.gui.util.Rect.new(190, _y0 + 280, 100, 40))
    end
    addGotoButton()
    addIgnoreErrorsButton()
    addXMinus1Button(guiHelpers._bigLinearShift)
    addXPlus1Button(guiHelpers._bigLinearShift)
    addYMinus1Button(guiHelpers._bigLinearShift)
    addYPlus1Button(guiHelpers._bigLinearShift)
    addZMinus1Button(guiHelpers._bigLinearShift)
    addZPlus1Button(guiHelpers._bigLinearShift)
    addRotXMinus1Button(guiHelpers._bigRotShift)
    addRotXPlus1Button(guiHelpers._bigRotShift)
    addRotYMinus1Button(guiHelpers._bigRotShift)
    addRotYPlus1Button(guiHelpers._bigRotShift)
    addRotZMinus1Button(guiHelpers._bigRotShift)
    addRotZPlus1Button(guiHelpers._bigRotShift)

    -- window:setHighlighted(true)
    local position = api.gui.util.getMouseScreenPos()
    window:setPosition(position.x + _windowXShift, position.y + _windowYShift)
    window:addHideOnCloseHandler()
end

guiHelpers.showWarningWindowWithMessage = function(text)
    guiHelpers.isShowingWarning = true
    local layout = api.gui.layout.BoxLayout.new('VERTICAL')
    local window = api.gui.util.getById(_warningWindowWithMessageId)
    if window == nil then
        window = api.gui.comp.Window.new(_texts.shiftWindowTitle, layout)
        window:setId(_warningWindowWithMessageId)
    else
        window:setContent(layout)
        window:setVisible(true, false)
    end

    layout:addItem(api.gui.comp.TextView.new(text))

    window:setHighlighted(true)
    local position = api.gui.util.getMouseScreenPos()
    window:setPosition(position.x + _windowXShift, position.y)
    -- window:addHideOnCloseHandler()
    window:onClose(
        function()
            window:setVisible(false, false)
        end
    )
end

guiHelpers.showWarningWindowWithState = function(text)
    guiHelpers.isShowingWarning = true
    local layout = api.gui.layout.BoxLayout.new('VERTICAL')
    local window = api.gui.util.getById(_warningWindowWithStateId)
    if window == nil then
        window = api.gui.comp.Window.new(_texts.shiftWindowTitle, layout)
        window:setId(_warningWindowWithStateId)
    else
        window:setContent(layout)
        window:setVisible(true, false)
    end

    layout:addItem(api.gui.comp.TextView.new(text))

    window:setHighlighted(true)
    local position = api.gui.util.getMouseScreenPos()
    window:setPosition(position.x + _windowXShift, position.y)
    -- window:addHideOnCloseHandler()
    window:onClose(
        function()
            window:setVisible(false, false)
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                constants.eventId,
                constants.events.hide_warnings,
                {}
            ))
        end
    )
end

local _modifyOnOffButtonLayout = function(layout, isOn)
    if isOn then
        layout:addItem(api.gui.comp.ImageView.new('ui/design/components/checkbox_valid.tga'), api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
        layout:addItem(api.gui.comp.TextView.new(_texts.operationOn), api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
    else
        layout:addItem(api.gui.comp.ImageView.new('ui/design/components/checkbox_invalid.tga'), api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
        layout:addItem(api.gui.comp.TextView.new(_texts.operationOff), api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
    end
end

guiHelpers.initNotausButton = function(isBoardsOn, funcOfBool)
    if api.gui.util.getById(_operationOnOffButtonId) then return end

    local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
    _modifyOnOffButtonLayout(buttonLayout, isBoardsOn)
    local button = api.gui.comp.ToggleButton.new(buttonLayout)
    button:setSelected(isBoardsOn, false)
    button:onToggle(function(isOn) -- isOn is boolean
        print('toggled; isOn = ', isOn)
        while buttonLayout:getNumItems() > 0 do
            local item0 = buttonLayout:getItem(0)
            buttonLayout:removeItem(item0)
        end
        _modifyOnOffButtonLayout(buttonLayout, isOn)
        button:setSelected(isOn, false)
        funcOfBool(isOn)
    end)

    button:setId(_operationOnOffButtonId)

    api.gui.util.getById('gameInfo'):getLayout():addItem(button)
end

return guiHelpers
