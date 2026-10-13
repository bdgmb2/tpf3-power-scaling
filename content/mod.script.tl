local power = ug_require "vehicle_power_config_1::/power.tl" as table

local mod = {}

mod.postRunFn = function(_captureParams : table, _configDict : {{string, string}}, allModParams : {string : {string : integer}})
	local params = allModParams[getCurrentModId()]
	local config : {string : any} = {
		road = params.power_road,
		rail = params.power_rail,
		water = params.power_water,
		air = params.power_air,
		scaleTractiveEffort = params.tractive_effort == 1,
	}
	local apply = (power as {string : function}).apply
	apply(config)
end

return mod
