-- Active level: configs/level.lua default + optional save override (key "level").

local level_mod = require "common.level"
local save_data = require "common.save_data"

local M = {}

local SAVE_KEY = "level"
local active = nil

local function load_saved()
	local data = save_data.load(SAVE_KEY)
	if not data or not next(data) then
		return nil
	end
	data = save_data.tonum_keys(data)
	local ok, level_or_err = pcall(level_mod.normalize, data)
	if not ok then
		print("[level_store] bad saved level, using default:", level_or_err)
		return nil
	end
	return level_or_err
end

function M.default()
	return level_mod.default_from_configs()
end

function M.get()
	if not active then
		active = load_saved() or M.default()
	end
	return active
end

function M.set(level)
	active = level_mod.normalize(level)
	save_data.save(SAVE_KEY, active)
	return active
end

function M.reset_default()
	active = M.default()
	-- Full wipe: default level + player progress (balls, score, hits, regen).
	save_data.save({
		[SAVE_KEY] = nil,
		balls = active.game.balls_start,
		regen_elapsed = 0,
		score = 0,
		total_hits = 0,
		hits = {},
		level_key = "",
	})
	return active
end

function M.clone_active()
	return level_mod.normalize(M.get())
end

return M
