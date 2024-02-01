local logger = require('lolloConMover.logger')
local utils = require('lolloConMover.utils')

function data()
	local function loadConstructionFunc(fileName, data)
		if not(data) or (type(data.updateFn) ~= 'function') then return data end

		-- LOLLO TODO do we need this? We probably do with some mods. I took it out with minor 13.
		-- if type(data.upgradeFn) ~= 'function' then
		-- 	data.upgradeFn = function(_) return {} end
		-- else
		-- 	logger.print('upgradeFn() found for', fileName)
		-- end

		local _originalUpdateFn = data.updateFn
		data.updateFn = function(params)
			local result = _originalUpdateFn(params)
			if not(result) then
				logger.print('no result')
				return result
			end

			logger.print('construction.updateFn starting for con with filename = ' .. fileName .. '; params.upgrade = ' .. tostring(params.upgrade))
			logger.debugPrint(data)

			-- if not(params.upgrade) then return result end

			if not(result.edgeLists) or #result.edgeLists == 0 then
				-- if not(result.terrainAlignmentLists) then
				-- 	result.terrainAlignmentLists = utils.getDummyTerrainAlignmentLists()
				-- end
				if not(result.groundFaces) then
					result.groundFaces = utils.getDummyGroundFaces()
				end
			end

			return result
		end -- end of updateFn

		return data
	end

	return {
		info = {
			minorVersion = 10,
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
			}
		},
		runFn = function (settings, modParams)
			addModifier('loadConstruction', loadConstructionFunc)
		end,
	}
end
