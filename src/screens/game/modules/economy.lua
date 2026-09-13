-- Balls / regen state. Instance per game session (not a module singleton).

local level_cfg = require "configs.level"

local M = {}
local Eco = {}
Eco.__index = Eco

function M.new(game_cfg)
	local self = setmetatable({}, Eco)
	self.cfg = game_cfg or level_cfg.game
	self.balls = self.cfg.balls_start
	self.regen_elapsed = 0
	return self
end

function Eco:set_cfg(game)
	self.cfg = game or level_cfg.game
end

function Eco:init(start_balls, elapsed)
	self.balls = start_balls or self.cfg.balls_start
	self.regen_elapsed = elapsed or 0
end

function Eco:get_cfg()
	return self.cfg
end

function Eco:get_balls()
	return self.balls
end

function Eco:get_regen_elapsed()
	return self.regen_elapsed
end

function Eco:at_regen_cap()
	return self.balls >= self.cfg.balls_regen_cap
end

function Eco:regen_remaining()
	if self:at_regen_cap() then
		return nil
	end
	return math.max(0, self.cfg.regen_one_ball_seconds - self.regen_elapsed)
end

--- @return boolean true if at least one ball was added
function Eco:update(dt)
	if self:at_regen_cap() then
		self.regen_elapsed = 0
		return false
	end

	self.regen_elapsed = self.regen_elapsed + dt
	local changed = false
	local period = self.cfg.regen_one_ball_seconds
	while self.balls < self.cfg.balls_regen_cap and self.regen_elapsed >= period do
		self.regen_elapsed = self.regen_elapsed - period
		self.balls = self.balls + 1
		changed = true
	end
	if self:at_regen_cap() then
		self.regen_elapsed = 0
	end
	return changed
end

function Eco:try_spend(n)
	n = n or 1
	if self.balls < n then
		return false
	end
	self.balls = self.balls - n
	return true
end

--- Cheat / test add — may go above balls_regen_cap.
function Eco:add(n)
	n = n or self.cfg.cheat_add_balls
	self.balls = self.balls + n
end

return M
