local conChooser = require('lolloConMover.conChooser')
local modSettings = require('lolloConMover.modSettings')

function data()
	return {
		info = {
			minorVersion = 16,
			severityAdd = "NONE",
			severityRemove = "NONE",
			name = _("ModName"),
			description = _("ModDesc"),
			tags = { "Misc", "Script Mod" },
			visible = true,
			authors = {
                {
					name = "lollus",
					role = "CREATOR"
				}
			},
			params = {
				{
					key = 'forceOtherCons',
					name = _('ForceOtherCons'),
					values = { 'OFF', 'ON' },
                    defaultIndex = 1, -- LOLLO NOTE set this directly to avoid crashes; keep modSettings up to date if you alter this
				},
            },
		},
		runFn = function (settings, modParams)
			modSettings.setModParamsFromRunFn(modParams)
			if game.config._lolloConMover.forceOtherCons ~= 1 then return end

			addModifier('loadConstruction', conChooser.loadConstructionFunc)
		end,
	}
end
