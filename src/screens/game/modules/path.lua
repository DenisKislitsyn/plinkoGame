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
	local best, best_d = pins[1], math.huge
	for _, p in ipairs(pins) do
		local d = math.abs(p.x - x)
		if d < best_d then
			best, best_d = p, d
		end
	end
	return best
end

function M.build(pin_rows, spawn, basket, basket_index)
	local rows = #pin_rows
	local top = pin_rows[rows]
	-- Top row with several pins: always enter via the pin under the hole.
	local start_pin = closest_pin(top.pins, spawn.x)
	local start_col = start_pin.index or 1
	local rights_already = start_col - 1
	local rights_need = clamp((basket_index - 1) - rights_already, 0, rows)
	local decisions = {}
	for i = 1, rows do
		decisions[i] = i <= rights_need
	end
	table.shuffle(decisions)

	local R = cfg.ball_radius + cfg.pin_radius
	local bias = cfg.hit_bias * R
	local basket_w = basket.width or consts.BOARD.BASKET_WIDTH
	local bx = basket.x + (math.random() * 2 - 1) * math.min(cfg.basket_jitter, basket_w * 0.45)
	local by = basket.y
	local fall_span = math.max(spawn.y - by, 1)

	local hops = {}
	local rights = rights_already
	for i = 1, rows do
		local row = pin_rows[rows - i + 1]
		local pin
		if i == 1 then
			pin = start_pin
		else
			local idx = clamp(rights + 1, 1, #row.pins)
			pin = assert(row.pins[idx], "missing pin for path hop")
		end
		local dir = decisions[i] and 1 or -1
		local ox
		if i == 1 then
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
		hops[i] = { pin = pin, dir = dir, hx = hx, hy = hy, ox = ox, drop = i == 1 }
		if decisions[i] then
			rights = rights + 1
		end
	end

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
	end

	pts[#pts + 1] = { x = bx, y = by, kind = "arc", basket = true }
	return pts
end

return M
