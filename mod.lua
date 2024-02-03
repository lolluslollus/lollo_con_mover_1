local logger = require('lolloConMover.logger')
local stringUtils = require('lolloConMover.stringUtils')
local utils = require('lolloConMover.utils')

function data()
	local _allowedConTypes = {
		'ASSET_DEFAULT',
		'ASSET_TRACK',
		'STREET_CONSTRUCTION',
		'TRACK_CONSTRUCTION',
	}
	local _excludedConFileNames = {
		'wk_arrow_end.con',
		'wk_arrow_start.con',
		'wk_info.con',
		'wk_marker_01.con',
		'wk_marker_02.con',
		'wk_mrkx_delete_edges.con',
		'wk_mrkx_make_parallel.con',
		'wk_mrkx_modify.con',
	}
	local function loadConstructionFunc(fileName, data)
		if not(data) or (type(data.updateFn) ~= 'function') then return data end

		local isConTypeAllowed = false
		for _, cty in pairs(_allowedConTypes) do
			if data.type == cty then isConTypeAllowed = true break end
		end
		if not(isConTypeAllowed) then return data end

		for _, fna in pairs(_excludedConFileNames) do
			if stringUtils.stringEndsWith(fileName, fna) then return data end
		end

		-- LOLLO TODO do we need this? We probably do with some mods. I took it out with minor 13.
		-- if type(data.upgradeFn) ~= 'function' then
		-- 	data.upgradeFn = function(_) return {} end
		-- else
		-- 	logger.print('upgradeFn() found for', fileName)
		-- end
		logger.print('loadConstructionFunc starting for con with filename = ' .. fileName .. '; data.type = ' .. tostring(data.type))
		-- 1962843709 (40 tons Truck Set) has a dynamic updateFn and does not work, neither with runFn() nor with postRunFn()
		-- if stringUtils.stringEndsWith(fileName, 'nando_truck_set.con') then logger.print('nando con data =') logger.debugPrint(data) end
		-- if stringUtils.stringEndsWith(fileName, 'nando_truck_set.script') then logger.print('nando script data =') logger.debugPrint(data) end

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
			minorVersion = 12,
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
