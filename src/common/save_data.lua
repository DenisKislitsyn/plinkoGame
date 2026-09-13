local savetable = require "ludobits.m.io.savetable"
local level_cfg = require "configs.level"

local M = {}

local save_file = "gamedata"
local save_data = savetable.load(save_file)

local def_save = {
	sound = true,
	balls = level_cfg.game.balls_start,
	regen_elapsed = 0,
	score = 0,
	total_hits = 0,
	hits = {},
	level_key = "",
}

local t_type = "table"

local table_merge
table_merge = function(t, defs)
	for k, v in pairs(defs) do
		if type(v) == t_type and type(t[k]) == t_type then
			table_merge(t[k], defs[k])
		else
			if t[k] == nil then
				t[k] = table.deepcopy(v)
			end
		end
	end
	return t
end

function M.tonum_keys(t)
	if type(t) == t_type then
		local new_table = {}
		for k, v in pairs(t) do
			new_table[tonumber(k) or k] = M.tonum_keys(v)
		end
		return new_table
	end
	return t
end

function M.save(key, value)
	if type(key) == t_type and value == nil then
		for k, v in pairs(key) do
			save_data[k] = v
		end
	elseif key ~= nil then
		save_data[key] = value
	end
	savetable.save(save_data, save_file)
end

function M.load(key)
	return save_data[key]
end

function M.reset()
	save_data = table.deepcopy(def_save)
	savetable.save(save_data, save_file)
end

function M.initialize(callback)
	if not save_data or not next(save_data) then
		save_data = def_save
		M.save()
	else
		table_merge(save_data, def_save)
		M.save()
	end

	callback()
end

return M
