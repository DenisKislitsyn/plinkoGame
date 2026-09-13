-- Level editor mutators (add/remove basket, weight/score, rebuild layout).

local board_layout = require "common.board_layout"
local schema = require "common.level_schema"

local M = {}

function M.row_count(level)
	local _, rows = board_layout.layout_to_pin_rows(level.layout)
	return #rows
end

function M.rebuild_layout(level, bounds)
	level.layout = board_layout.build_pyramid_layout(level.baskets, bounds or schema.default_bounds())
	return level
end

function M.add_basket(level, bounds)
	if #level.baskets >= schema.MAX_BASKETS then
		return false
	end
	local n = #level.baskets + 1
	level.baskets[n] = { id = n, weight = 1, score = 10 }
	for i, b in ipairs(level.baskets) do
		b.id = i
	end
	level.max_baskets = schema.MAX_BASKETS
	level.min_baskets = schema.MIN_BASKETS
	M.rebuild_layout(level, bounds)
	return true
end

function M.remove_basket(level, bounds)
	if #level.baskets <= schema.MIN_BASKETS then
		return false
	end
	level.baskets[#level.baskets] = nil
	for i, b in ipairs(level.baskets) do
		b.id = i
	end
	level.max_baskets = schema.MAX_BASKETS
	level.min_baskets = schema.MIN_BASKETS
	M.rebuild_layout(level, bounds)
	return true
end

function M.adjust_weight(level, basket_index, delta)
	local b = level.baskets[basket_index]
	if not b then
		return false
	end
	b.weight = math.max(schema.WEIGHT_MIN, schema.round_weight((b.weight or 1) + delta))
	return true
end

function M.adjust_score(level, basket_index, delta)
	local b = level.baskets[basket_index]
	if not b then
		return false
	end
	b.score = math.max(schema.SCORE_MIN, math.floor((b.score or 10) + delta + 0.5))
	return true
end

return M
