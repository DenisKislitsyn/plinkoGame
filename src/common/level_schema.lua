-- Level schema: normalize, defaults, composition key, editor step constants.

local level_cfg = require "configs.level"
local camera_utils = require "common.camera_utils"
local board_layout = require "common.board_layout"

local M = {}

M.MAX_BASKETS = 11
M.MIN_BASKETS = 5
M.WEIGHT_STEP = 1
M.WEIGHT_MIN = 1
M.SCORE_STEP = 10
M.SCORE_MIN = 1

local function default_bounds()
	return camera_utils.design_bounds()
end

function M.weight_step()
	return M.WEIGHT_STEP
end

function M.score_step()
	return M.SCORE_STEP
end

local function round_weight(v)
	return math.floor(v + 0.5)
end

function M.round_weight(v)
	return round_weight(v)
end

--- Fingerprint of level content. Any edit (baskets/weights/scores/layout/game)
--- that changes this key resets player progress on next game load.
function M.composition_key(level)
	local baskets = {}
	for i, b in ipairs(level.baskets or {}) do
		baskets[i] = string.format("%s:%s:%s", b.id or i, b.weight or 0, b.score or 0)
	end
	local layout = {}
	for i, p in ipairs(level.layout or {}) do
		layout[i] = string.format("%.1f,%.1f", p.x or 0, p.y or 0)
	end
	local g = level.game or {}
	local game = string.format(
		"%s,%s,%s,%s,%s",
		g.balls_start or 0,
		g.regen_one_ball_seconds or 0,
		g.balls_regen_cap or 0,
		g.cheat_add_balls or 0,
		g.drop_many_count or 0
	)
	return table.concat(baskets, ";")
		.. "|" .. table.concat(layout, ";")
		.. "|" .. game
end

local function normalize_baskets(raw)
	local out = {}
	for i, b in ipairs(raw or {}) do
		out[i] = {
			id = b.id or i,
			weight = math.max(M.WEIGHT_MIN, round_weight(b.weight or 1)),
			score = b.score or 10,
		}
	end
	return out
end

local function normalize_game(raw)
	local d = level_cfg.game or {}
	raw = raw or {}
	return {
		balls_start = raw.balls_start or d.balls_start,
		regen_one_ball_seconds = raw.regen_one_ball_seconds or d.regen_one_ball_seconds,
		balls_regen_cap = raw.balls_regen_cap or d.balls_regen_cap,
		cheat_add_balls = raw.cheat_add_balls or d.cheat_add_balls,
		drop_many_count = raw.drop_many_count or d.drop_many_count,
		drop_many_spawn_interval_seconds = raw.drop_many_spawn_interval_seconds
			or d.drop_many_spawn_interval_seconds,
	}
end

local function normalize_layout(raw)
	local out = {}
	for i, p in ipairs(raw or {}) do
		out[i] = { x = p.x or 0, y = p.y or 0 }
	end
	return out
end

function M.normalize_layout(raw)
	return normalize_layout(raw)
end

function M.normalize_game(raw)
	return normalize_game(raw)
end

function M.normalize(level)
	level = table.deepcopy(level or {})
	level.version = level.version or 1
	level.max_baskets = M.MAX_BASKETS
	level.min_baskets = M.MIN_BASKETS
	level.max_rows = nil
	level.min_rows = nil
	level.baskets = normalize_baskets(level.baskets)
	level.game = normalize_game(level.game)
	level.layout = normalize_layout(level.layout)

	while #level.baskets > level.max_baskets do
		level.baskets[#level.baskets] = nil
	end
	for i, b in ipairs(level.baskets) do
		b.id = i
	end

	if #level.baskets < level.min_baskets then
		error("level needs at least " .. level.min_baskets .. " baskets")
	end

	return level
end

function M.default_from_configs(bounds)
	bounds = bounds or default_bounds()
	local baskets = {}
	for i, b in ipairs(level_cfg.baskets or {}) do
		baskets[i] = { id = b.id or i, weight = b.weight, score = b.score }
	end
	local layout = normalize_layout(level_cfg.layout)
	if #layout == 0 then
		layout = board_layout.build_pyramid_layout(baskets, bounds)
	end
	return M.normalize({
		version = level_cfg.version or 1,
		max_baskets = M.MAX_BASKETS,
		min_baskets = M.MIN_BASKETS,
		baskets = baskets,
		layout = layout,
		game = normalize_game(level_cfg.game),
	})
end

function M.default_bounds()
	return default_bounds()
end

return M
