-- Animate along path waypoints (quadratic Bezier, chord-length timing).

local cfg = require "configs.fall"
local consts = require "common.consts"

local M = {}

local function fire_hit(wp)
	if wp and wp.pin_hit and wp.pin_go and not wp._fired then
		wp._fired = true
		msg.post(wp.pin_go, consts.MSG.PIN_HIT)
	end
end

local function bezier(ax, ay, cx, cy, bx, by, t)
	local u = 1 - t
	return u * u * ax + 2 * u * t * cx + t * t * bx,
		u * u * ay + 2 * u * t * cy + t * t * by
end

local function ctrl(a, b)
	local mx = (a.x + b.x) * 0.5
	if b.kind == "drop" then
		return mx, (a.y + b.y) * 0.5
	end
	if b.kind == "bounce" then
		return mx, math.max(a.y, b.y) + 12
	end
	return mx, a.y * 0.7 + b.y * 0.3
end

function M.start(ball, pts)
	local segs, total = {}, 0
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local cx, cy = ctrl(a, b)
		local dx, dy = b.x - a.x, b.y - a.y
		local len = math.sqrt(dx * dx + dy * dy) * 1.15
		segs[i] = { a = a, b = b, cx = cx, cy = cy, len = len }
		total = total + len
	end
	ball.segs = segs
	ball.path_total = math.max(total, 1)
	ball.fall_t = 0
	ball.fall_done = false
	ball.seg_i = 1
	-- Reuse one vector3 for go.set_position (no alloc per frame).
	ball.pos = go.get_position(ball.go)
end

function M.step(ball, dt)
	if ball.fall_done then
		return true
	end

	ball.fall_t = ball.fall_t + dt
	local u = math.min(ball.fall_t / cfg.duration_seconds, 1)
	u = u ^ cfg.gravity

	local dist = u * ball.path_total
	local segs = ball.segs
	local acc, i = 0, 1
	while i < #segs and acc + segs[i].len < dist do
		acc = acc + segs[i].len
		i = i + 1
	end

	while ball.seg_i < i do
		fire_hit(segs[ball.seg_i].b)
		ball.seg_i = ball.seg_i + 1
	end

	local seg = segs[i]
	local t = seg.len > 0 and (dist - acc) / seg.len or 1
	local x, y = bezier(seg.a.x, seg.a.y, seg.cx, seg.cy, seg.b.x, seg.b.y, t)
	local pos = ball.pos
	pos.x = x
	pos.y = y
	go.set_position(pos, ball.go)

	if u >= 1 or (seg.b.basket and t >= 1) then
		fire_hit(seg.b)
		pos.x = seg.b.x
		pos.y = seg.b.y
		go.set_position(pos, ball.go)
		ball.fall_done = true
		return true
	end
	return false
end

return M
