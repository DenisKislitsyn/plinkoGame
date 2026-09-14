-- Path: pick basket (caller) → L/R budget + shuffle → hop pins top→bottom.
-- Missing/empty row = skip (drop) to the next pin; always finish in the target basket.

local cfg = require "configs.fall"
local consts = require "common.consts"

local M = {}

local function clamp(v, lo, hi)
	return math.max(lo, math.min(hi, v))
end

local function contact(pin, offset, R)
	offset = clamp(offset, -R * 0.9, R * 0.9)
	return pin.x + offset, pin.y + math.sqrt(R * R - offset * offset)
end

local function closest_pin(pins, x)
	local best, best_d = pins[1], nil
	for _, p in ipairs(pins) do
		local d = math.abs(p.x - x)
		if not best_d or d < best_d then
			best, best_d = p, d
		end
	end
	return best
end

local function count_occupied_rows(pin_rows)
	local n = 0
	for _, row in ipairs(pin_rows) do
		if row.pins and #row.pins > 0 then
			n = n + 1
		end
	end
	return n
end

function M.build(pin_rows, spawn, basket, basket_index)
	local rows = #pin_rows
	assert(rows > 0 and pin_rows[rows].pins[1], "need pin rows for path")

	-- 1) Target basket is already chosen by weights (basket / basket_index).
	local top = pin_rows[rows]
	local start_pin = closest_pin(top.pins, spawn.x)
	local start_col = start_pin.index or 1

	-- 2) How many right bounces are required to line up with that basket.
	-- 3) The rest are lefts; shuffle so the order looks natural.
	local hops_n = count_occupied_rows(pin_rows)
	local rights_already = start_col - 1
	local rights_need = clamp((basket_index - 1) - rights_already, 0, hops_n)
	local decisions = {}
	for i = 1, hops_n do
		decisions[i] = i <= rights_need
	end
	table.shuffle(decisions)

	local R = cfg.ball_radius + cfg.pin_radius
	local bias = cfg.hit_bias * R
	local basket_w = basket.width or consts.BOARD.BASKET_WIDTH
	local bx = basket.x + (math.random() * 2 - 1) * math.min(cfg.basket_jitter, basket_w * 0.45)
	local by = basket.y
	local fall_span = math.max(spawn.y - by, 1)

	-- 4) Walk top → bottom. Empty row = skip (no bounce). Else hit column by rights.
	local hops = {}
	local rights = rights_already
	local di = 1
	local pending_skips = {}
	local first = true

	for i = 1, rows do
		local row = pin_rows[rows - i + 1]
		if not row.pins or #row.pins == 0 then
			pending_skips[#pending_skips + 1] = row.y
		else
			local pin
			if first then
				pin = start_pin
				first = false
			else
				local idx = clamp(rights + 1, 1, #row.pins)
				pin = assert(row.pins[idx], "missing pin for path hop")
			end

			local go_right = decisions[di]
			di = di + 1
			local dir = go_right and 1 or -1

			local ox
			if #hops == 0 then
				local natural = spawn.x - pin.x
				if natural * dir > 0 and math.abs(natural) > 1 then
					ox = clamp(natural, -R * 0.9, R * 0.9)
				else
					ox = dir * bias * 0.6
				end
			else
				ox = dir * bias + (math.random() * 2 - 1) * bias * 0.4
			end

			local hx, hy = contact(pin, ox, R)
			hops[#hops + 1] = {
				pin = pin,
				dir = dir,
				hx = hx,
				hy = hy,
				ox = ox,
				drop = #hops == 0,
				skips = pending_skips,
			}
			pending_skips = {}

			if go_right then
				rights = rights + 1
			end
		end
	end

	-- Trailing empty rows under the last pin → drop toward the basket.
	if #hops > 0 then
		local last = hops[#hops]
		for _, y in ipairs(pending_skips) do
			last.skips[#last.skips + 1] = y
		end
	end

	-- 5) Waypoints for fall animation; endpoint is always the chosen basket.
	local pts = { { x = spawn.x, y = spawn.y } }
	for i, h in ipairs(hops) do
		pts[#pts + 1] = {
			x = h.hx, y = h.hy,
			kind = h.drop and "drop" or "arc",
			pin_hit = true,
			pin_go = h.pin.go,
		}

		local bounce_dir = h.dir
		if math.abs(h.ox) >= 1 then
			bounce_dir = h.ox > 0 and 1 or -1
		end

		local nx = hops[i + 1] and hops[i + 1].hx or bx
		local ndir = hops[i + 1] and hops[i + 1].dir or bounce_dir
		local reverse = (nx - h.pin.x) * bounce_dir < 0 or ndir ~= bounce_dir

		local speed_t = clamp((spawn.y - h.hy) / fall_span, 0, 1)
		local speed_k = cfg.bounce_speed_min + (cfg.bounce_speed_max - cfg.bounce_speed_min) * speed_t
		local su = cfg.bounce_up * speed_k
		local ss = cfg.bounce_side * (0.75 + 0.25 * speed_t)
		local ax = h.pin.x + bounce_dir * ss
		if reverse then
			su = su * 1.2
			ss = ss * 0.3
			ax = h.pin.x * 0.6 + nx * 0.4 + bounce_dir * ss * 0.5
		end

		pts[#pts + 1] = { x = ax, y = h.pin.y + R + su, kind = "bounce", dir = bounce_dir }

		for _, sy in ipairs(h.skips or {}) do
			pts[#pts + 1] = { x = h.pin.x, y = sy, kind = "drop" }
		end
	end

	pts[#pts + 1] = { x = bx, y = by, kind = "arc", basket = true }
	return pts
end

return M
