-- Basket list for RNG. Instance per game session.

local level_cfg = require "configs.level"
local level_rng = require "common.level_rng"

local M = {}
local State = {}
State.__index = State

function M.new(list)
	return setmetatable({ list = list or level_cfg.baskets }, State)
end

function State:set_list(list)
	self.list = list
end

function State:clear()
	self.list = nil
end

function State:get_list()
	return self.list or level_cfg.baskets
end

function State:count()
	return #self:get_list()
end

function State:total_weight()
	return level_rng.total_weight(self:get_list())
end

function State:pick_by_weight(rnd)
	return level_rng.pick_by_weight(self:get_list(), rnd)
end

return M
