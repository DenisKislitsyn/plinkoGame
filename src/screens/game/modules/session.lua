-- In-flight balls: spawn, drop, burst timer, step + resolve.

local path = require "screens.game.modules.path"
local fall = require "screens.game.modules.fall"
local consts = require "common.consts"
local camera_utils = require "common.camera_utils"
local debug_stats = require "screens.game.modules.debug_stats"

local M = {}

local function speed_scale(self)
	return self.speed_x2 and 2 or 1
end

function M.cancel_spawn_timer(self)
	if self.spawn_timer then
		timer.cancel(self.spawn_timer)
		self.spawn_timer = nil
	end
	self.spawn_left = 0
end

function M.spawn_ball(self)
	local s = assert(self.spawn, "spawn hole missing")
	local target = self.baskets_rng:pick_by_weight(math.random())
	local slot = assert(self.basket_by_id[target.id], "unknown basket id")

	local jitter = consts.BOARD.BALL_SPAWN_JITTER_X
	local x = s.x + (math.random() * 2 - 1) * jitter
	local pos = vmath.vector3(x, s.y, consts.BOARD.BALL_Z)
	local id = factory.create(consts.URL.BALL_FACTORY, pos)

	local spawn = { x = x, y = s.y }
	local waypoints = path.build(self.pin_rows, spawn, slot, slot.index)

	local ball = {
		go = id,
		target_id = target.id,
		target_score = target.score,
		target_x = slot.x,
		resolved = false,
	}
	fall.start(ball, waypoints)
	self.balls[id] = ball
	camera_utils.shake()
	return id
end

local function resolve_ball(self, ball, push_ui, save_progress)
	if ball.resolved then
		return
	end
	ball.resolved = true

	local tid = ball.target_id
	self.hits[tid] = (self.hits[tid] or 0) + 1
	self.total_hits = self.total_hits + 1
	self.score = self.score + (ball.target_score or 0)

	local id = ball.go
	self.balls[id] = nil
	go.delete(id)
	debug_stats.mark_dirty()
	push_ui(self)
	save_progress(self)
end

function M.drop_ball(self, push_ui, save_progress)
	if not self.economy:try_spend(1) then
		return false
	end
	M.spawn_ball(self)
	push_ui(self)
	save_progress(self)
	return true
end

function M.drop_many(self, count, push_ui, save_progress)
	local cfg = self.economy:get_cfg()
	count = count or cfg.drop_many_count
	-- Spend whatever is available (partial burst), not all-or-nothing.
	count = math.min(count, self.economy:get_balls())
	if count <= 0 or not self.economy:try_spend(count) then
		return false
	end
	push_ui(self)
	save_progress(self)

	if self.spawn_timer then
		self.spawn_left = (self.spawn_left or 0) + count
		return true
	end

	M.spawn_ball(self)
	self.spawn_left = count - 1
	if self.spawn_left <= 0 then
		return true
	end

	local interval = cfg.drop_many_spawn_interval_seconds / speed_scale(self)
	self.spawn_timer = timer.delay(interval, true, function()
		if self.spawn_left <= 0 then
			M.cancel_spawn_timer(self)
			return
		end
		M.spawn_ball(self)
		self.spawn_left = self.spawn_left - 1
		if self.spawn_left <= 0 then
			M.cancel_spawn_timer(self)
		end
	end)
	return true
end

function M.update_balls(self, dt, push_ui, save_progress)
	local to_resolve = {}

	for _, ball in pairs(self.balls) do
		if not ball.resolved then
			if fall.step(ball, dt) then
				to_resolve[#to_resolve + 1] = ball
			end
		end
	end

	for i = 1, #to_resolve do
		resolve_ball(self, to_resolve[i], push_ui, save_progress)
	end
end

return M
