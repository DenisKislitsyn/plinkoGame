-- World-space board geometry (shared by game + editor). No GO / screen deps.

local consts = require "common.consts"
local camera_utils = require "common.camera_utils"

local M = {}

local Y_GROUP_EPS = 1.5
local PIN_MATCH_EPS = 4

local function bounds_or_design(bounds)
	return bounds or camera_utils.design_bounds()
end

function M.metrics(baskets, bounds)
	bounds = bounds_or_design(bounds)
	local n = #baskets
	assert(n >= 2, "need at least 2 baskets")
	local left = bounds.x
	local right = bounds.z
	local bottom = bounds.w
	local usable = right - left - 2 * consts.BOARD.MARGIN_X
	local slot_w = usable / n
	local basket_y = bottom + consts.BOARD.BASKET_Y_FROM_BOTTOM
	local basket1_x = left + consts.BOARD.MARGIN_X + slot_w * 0.5
	return {
		n = n,
		slot_w = slot_w,
		basket_y = basket_y,
		basket1_x = basket1_x,
		pin_cols = n - 1,
		y0 = basket_y + consts.BOARD.PIN_Y_ABOVE_BASKET,
		row_spacing = consts.BOARD.PIN_ROW_SPACING,
		basket_span_mid = basket1_x + (n - 1) * slot_w * 0.5,
		gap = consts.BOARD.BASKET_GAP,
		basket_height = consts.BOARD.BASKET_HEIGHT,
	}
end

local function stagger_active_span(metrics, row)
	local active_count = math.max(1, metrics.pin_cols - row)
	local y = metrics.y0 + row * metrics.row_spacing
	local first_active_x
	if active_count == 1 then
		first_active_x = metrics.basket_span_mid
	else
		first_active_x = metrics.basket1_x + (row + 1) * (metrics.slot_w * 0.5)
	end
	return first_active_x, y, active_count
end

local function row_slot_count(metrics, row)
	if row % 2 == 0 then
		return metrics.pin_cols
	end
	return math.max(1, metrics.pin_cols - 1)
end

local function row_first_x(metrics, row)
	return metrics.basket1_x + (row % 2 + 1) * (metrics.slot_w * 0.5)
end

function M.build_baskets(list, bounds)
	bounds = bounds_or_design(bounds)
	local m = M.metrics(list, bounds)
	local width = math.max(1, m.slot_w - m.gap)
	local out = {}
	for i, b in ipairs(list) do
		out[i] = {
			id = b.id,
			weight = b.weight,
			score = b.score,
			x = m.basket1_x + (i - 1) * m.slot_w,
			y = m.basket_y,
			z = consts.BOARD.BASKET_Z,
			width = width,
			height = m.basket_height,
		}
	end
	return out
end

function M.layout_to_pin_rows(layout)
	layout = layout or {}
	if #layout == 0 then
		return {}, {}
	end

	local sorted = {}
	for i, p in ipairs(layout) do
		sorted[i] = { x = p.x, y = p.y, z = p.z or consts.BOARD.PIN_Z }
	end
	table.sort(sorted, function(a, b)
		if math.abs(a.y - b.y) > Y_GROUP_EPS then
			return a.y < b.y
		end
		return a.x < b.x
	end)

	local rows = {}
	local cur = nil
	for _, p in ipairs(sorted) do
		if not cur or math.abs(p.y - cur.y) > Y_GROUP_EPS then
			cur = { row = #rows, count = 0, pins = {}, y = p.y }
			rows[#rows + 1] = cur
		end
		local idx = #cur.pins + 1
		local pin = {
			x = p.x,
			y = cur.y,
			z = p.z or consts.BOARD.PIN_Z,
			row = cur.row,
			index = idx,
		}
		cur.pins[idx] = pin
		cur.count = idx
	end

	local pins = {}
	for _, row in ipairs(rows) do
		for _, pin in ipairs(row.pins) do
			pins[#pins + 1] = pin
		end
	end
	return pins, rows
end

function M.pin_rows_to_layout(pin_rows)
	local layout = {}
	for _, row in ipairs(pin_rows or {}) do
		for _, pin in ipairs(row.pins or {}) do
			layout[#layout + 1] = { x = pin.x, y = pin.y }
		end
	end
	return layout
end

function M.build_pyramid_layout(baskets, bounds)
	local m = M.metrics(baskets, bounds)
	local row_count = m.n - 1
	local layout = {}
	for r = 0, row_count - 1 do
		local first_x, y, count = stagger_active_span(m, r)
		for i = 0, count - 1 do
			layout[#layout + 1] = {
				x = first_x + i * m.slot_w,
				y = y,
			}
		end
	end
	return layout
end

function M.apply_layout_to_slots(slots, layout)
	for _, s in ipairs(slots) do
		s.active = false
	end
	if not layout or #layout == 0 or #slots == 0 then
		return
	end
	local spacing = PIN_MATCH_EPS
	if #slots >= 2 then
		local dx = math.abs(slots[2].x - slots[1].x)
		if dx > 1 then
			spacing = dx * 0.45
		end
	end
	local eps2 = spacing * spacing
	for _, p in ipairs(layout) do
		local best, best_d2 = nil, eps2
		for _, s in ipairs(slots) do
			local ddx = s.x - (p.x or 0)
			local ddy = s.y - (p.y or 0)
			local d2 = ddx * ddx + ddy * ddy
			if d2 <= best_d2 then
				best = s
				best_d2 = d2
			end
		end
		if best then
			best.active = true
		end
	end
end

function M.layout_from_slots(slots)
	local layout = {}
	for _, s in ipairs(slots or {}) do
		if s.active then
			layout[#layout + 1] = { x = s.x, y = s.y }
		end
	end
	return layout
end

function M.toggle_slot(slots, index)
	local s = slots[index]
	if not s then
		return false
	end
	if s.active then
		local n_active = 0
		for _, o in ipairs(slots) do
			if o.active then
				n_active = n_active + 1
			end
		end
		if n_active <= 1 then
			return false
		end
		s.active = false
	else
		s.active = true
	end
	return true
end

function M.build_editor_pin_slots(baskets, bounds, layout)
	local m = M.metrics(baskets, bounds)
	local row_count = m.n - 1
	local slots = {}
	for r = 0, row_count - 1 do
		local count = row_slot_count(m, r)
		local first_x = row_first_x(m, r)
		local y = m.y0 + r * m.row_spacing
		local _, _, active_count = stagger_active_span(m, r)
		active_count = math.min(active_count, count)
		local pad_left = math.floor((count - active_count) / 2)
		for c = 0, count - 1 do
			slots[#slots + 1] = {
				x = first_x + c * m.slot_w,
				y = y,
				row = r,
				col = c,
				active = c >= pad_left and c < pad_left + active_count,
			}
		end
	end

	if layout and #layout > 0 then
		M.apply_layout_to_slots(slots, layout)
		local active = 0
		for _, s in ipairs(slots) do
			if s.active then
				active = active + 1
			end
		end
		if active < math.max(1, math.floor(#layout * 0.5)) then
			for _, s in ipairs(slots) do
				local count = row_slot_count(m, s.row)
				local _, _, active_count = stagger_active_span(m, s.row)
				active_count = math.min(active_count, count)
				local pad_left = math.floor((count - active_count) / 2)
				s.active = s.col >= pad_left and s.col < pad_left + active_count
			end
		end
	end
	return slots
end

function M.build_spawn(pin_rows, baskets)
	local top = pin_rows[#pin_rows]
	assert(top and top.pins[1], "need pin rows for spawn hole")
	local cx
	if baskets and #baskets > 0 then
		cx = (baskets[1].x + baskets[#baskets].x) * 0.5
	else
		cx = (top.pins[1].x + top.pins[#top.pins].x) * 0.5
	end
	return {
		x = cx,
		y = top.y + consts.BOARD.HOLE_Y_ABOVE_TOP_PIN,
		z = consts.BOARD.HOLE_Z,
	}
end

function M.build_level(bounds, level)
	assert(level and level.baskets, "level with baskets required")
	bounds = bounds_or_design(bounds)

	local baskets = M.build_baskets(level.baskets, bounds)
	local layout = level.layout
	if not layout or #layout == 0 then
		layout = M.build_pyramid_layout(level.baskets, bounds)
	end
	local pins, pin_rows = M.layout_to_pin_rows(layout)
	assert(#pin_rows > 0, "level layout produced no pin rows")
	return {
		baskets = baskets,
		pins = pins,
		pin_rows = pin_rows,
		spawn = M.build_spawn(pin_rows, baskets),
	}
end

function M.build_editor_field(level, bounds)
	assert(level and level.baskets, "level with baskets required")
	bounds = bounds_or_design(bounds)
	return {
		bounds = bounds,
		baskets = M.build_baskets(level.baskets, bounds),
		slots = M.build_editor_pin_slots(level.baskets, bounds, level.layout),
	}
end

return M
