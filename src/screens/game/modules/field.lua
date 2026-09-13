-- Spawn / clear field GOs (baskets, pins, hole).

local board_layout = require "common.board_layout"
local consts = require "common.consts"
local basket_tint = require "common.basket_tint"
local camera_utils = require "common.camera_utils"
local debug_stats = require "screens.game.modules.debug_stats"

local M = {}

function M.clear(self)
	if self.balls then
		for id in pairs(self.balls) do
			go.delete(id)
		end
	end
	self.balls = {}
	if self.baskets then
		for _, b in ipairs(self.baskets) do
			go.delete(b.go)
		end
	end
	if self.pins then
		for _, p in ipairs(self.pins) do
			go.delete(p.go)
		end
	end
	if self.hole and self.hole.go then
		go.delete(self.hole.go)
	end
	self.baskets = nil
	self.basket_by_id = nil
	self.pins = nil
	self.pin_rows = nil
	self.hole = nil
	self.spawn = nil
end

local function spawn_baskets(self, baskets)
	self.baskets = {}
	self.basket_by_id = {}

	local min_w, max_w = basket_tint.weight_range(baskets)

	for i, b in ipairs(baskets) do
		local pos = vmath.vector3(b.x, b.y, b.z or consts.BOARD.BASKET_Z)
		local id = factory.create(consts.URL.BASKET_FACTORY, pos)
		local w = b.width or consts.BOARD.BASKET_WIDTH
		local h = b.height or consts.BOARD.BASKET_HEIGHT
		local sprite = msg.url(nil, id, "sprite")
		go.set(sprite, consts.PROP.SIZE, vmath.vector3(w, h, 0))
		go.set(sprite, consts.PROP.TINT, basket_tint.for_weight(b.weight or 0, min_w, max_w))
		local slot = {
			go = id,
			id = b.id,
			index = i,
			weight = b.weight,
			score = b.score,
			x = b.x,
			y = b.y,
			width = w,
			height = h,
		}
		self.baskets[#self.baskets + 1] = slot
		self.basket_by_id[b.id] = slot
	end
end

local function spawn_pins(self, pins, pin_rows)
	self.pins = {}
	for _, p in ipairs(pins) do
		local pos = vmath.vector3(p.x, p.y, p.z or consts.BOARD.PIN_Z)
		local id = factory.create(consts.URL.PIN_FACTORY, pos)
		local slot = {
			go = id,
			row = p.row,
			index = p.index,
			x = p.x,
			y = p.y,
		}
		self.pins[#self.pins + 1] = slot
		local row = pin_rows[p.row + 1]
		if row and row.pins[p.index] then
			row.pins[p.index].go = id
		end
	end
end

local function spawn_hole(self, spawn)
	local pos = vmath.vector3(spawn.x, spawn.y, spawn.z or consts.BOARD.HOLE_Z)
	self.hole = {
		go = factory.create(consts.URL.HOLE_FACTORY, pos),
		x = spawn.x,
		y = spawn.y,
	}
	self.spawn = spawn
end

--- Build playfield from active level.
function M.build(self, level)
	M.clear(self)
	local bounds = camera_utils.design_bounds()
	local built = board_layout.build_level(bounds, level)
	self.pin_rows = built.pin_rows
	spawn_baskets(self, built.baskets)
	spawn_pins(self, built.pins, built.pin_rows)
	spawn_hole(self, built.spawn)
	debug_stats.set_baskets(self.baskets)
end

return M
