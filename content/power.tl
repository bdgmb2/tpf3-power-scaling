-- Scales vehicle power in the model repository. Runs from postRunFn only.

local power = {}

local CARRIER_KEYS = { "landVehicle", "waterVehicle", "airVehicle" }

-- modelName -> { carrier, engines = {{power, tractiveEffort}}, availPower, maxThrust }
local base : {string : table} = {}

local function metaOf(model : table, key : string) : table
	local metadata = model.metadata as table
	return metadata and metadata[key] as table
end

--- "road", "rail", "water" or "air"
local function classOf(model : table, key : string) : string
	if key == "waterVehicle" then return "water" end
	if key == "airVehicle" then return "air" end
	if metaOf(model, "railVehicle") then return "rail" end
	return "road"
end

local function snapshot(name : string, key : string, model : table)
	if base[name] then return end
	local meta = metaOf(model, key)
	local s : table = { carrier = key }
	if key == "landVehicle" then
		local engines : {table} = {}
		for i, e in ipairs(meta.engines as {table} or {}) do
			engines[i] = { power = e.power, tractiveEffort = e.tractiveEffort }
		end
		s.engines = engines
	elseif key == "waterVehicle" then
		s.availPower = meta.availPower
	else
		s.maxThrust = meta.maxThrust
	end
	base[name] = s
end

local function clamp(v : number) : number
	return math.max(0.05, math.min(20.0, v))
end

--- config = { road, rail, water, air (scale factors, default 1), scaleTractiveEffort (default true) }
function power.apply(config : table)
	local scaleTE = config.scaleTractiveEffort ~= false
	local count = 0
	for __, key in ipairs(CARRIER_KEYS) do
		api.res.modelRep.forEachModelWithMetadata(key, function(name : string)
			local id = api.res.modelRep.find(name)
			if id < 0 then return end
			local model = api.res.modelRep.getAsTable(id) as table
			snapshot(name, key, model)
			local s = base[name]
			local scale = clamp(config[classOf(model, key)] as number or 1.0)
			local meta = metaOf(model, key)
			if key == "landVehicle" then
				for i, e in ipairs(meta.engines as {table}) do
					local b = (s.engines as {table})[i]
					if b then
						e.power = (b.power as number) * scale
						if scaleTE and b.tractiveEffort then
							e.tractiveEffort = (b.tractiveEffort as number) * scale
						else
							e.tractiveEffort = b.tractiveEffort
						end
					end
				end
			elseif key == "waterVehicle" then
				meta.availPower = (s.availPower as number) * scale
			else
				meta.maxThrust = (s.maxThrust as number) * scale
			end
			api.res.modelRep.setAsTable(id, model)
			count = count + 1
		end)
	end
	log.warning("[VPC] scaled " .. tostring(count) .. " vehicle models")
end

return power
