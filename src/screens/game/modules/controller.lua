-- Game screen orchestrator: field + session + economy + persistence.

local field = require "screens.game.modules.field"
local session = require "screens.game.modules.session"
local economy_mod = require "screens.game.modules.economy"
local baskets_mod = require "screens.game.modules.baskets"
local debug_stats = require "screens.game.modules.debug_stats"
local consts = require "common.consts"
local save_data = require "common.save_data"
local level_schema = require "common.level_schema"
local level_store = require "common.level_store"

local M = {}

local function push_ui(self)
	msg.post(consts.URL.GAME_GUI, consts.MSG.UI_UPDATE, {
		balls = self.economy:get_balls(),
		regen = self.economy:regen_remaining(),
		score = self.score,
		drop_many_count = self.economy:get_cfg().drop_many_count,
		speed_x2 = self.speed_x2 and true or false,
	})
end

local function save_progress(self)
	save_data.save({
		balls = self.economy:get_balls(),
		regen_elapsed = self.economy:get_regen_elapsed(),
		score = self.score,
		total_hits = self.total_hits,
		hits = self.hits,
		level_key = self.level_key,
	})
end

local function load_progress(self, level)
	local key = level_schema.composition_key(level)
	self.level_key = key

	local same = save_data.load("level_key") == key
	if same then
		self.score = save_data.load("score") or 0
		self.total_hits = save_data.load("total_hits") or 0
		self.hits = save_data.tonum_keys(save_data.load("hits")) or {}
		self.economy:init(save_data.load("balls"), save_data.load("regen_elapsed"))
	else
		-- Level changed / reset: wipe score, hits, and ball inventory.
		self.score = 0
		self.total_hits = 0
		self.hits = {}
		self.economy:init(level.game.balls_start, 0)
	end
end

function M.init(self)
	self.balls = {}
	self.speed_x2 = false
	self.spawn_timer = nil
	self.spawn_left = 0
	self.ui_timer_accum = 0

	local level = level_store.get()
	self.economy = economy_mod.new(level.game)
	self.baskets_rng = baskets_mod.new(level.baskets)
	load_progress(self, level)
	field.build(self, level)

	push_ui(self)
	save_progress(self)
end

function M.final(self)
	session.cancel_spawn_timer(self)
	save_progress(self)
	debug_stats.set_baskets(nil)
	field.clear(self)
	if self.baskets_rng then
		self.baskets_rng:clear()
	end
end

function M.update(self, dt)
	dt = dt * (self.speed_x2 and 2 or 1)
	local gained = self.economy:update(dt)
	if gained then
		self.ui_timer_accum = 0
		push_ui(self)
		save_progress(self)
	elseif not self.economy:at_regen_cap() then
		self.ui_timer_accum = (self.ui_timer_accum or 0) + dt
		if self.ui_timer_accum >= 0.1 then
			self.ui_timer_accum = 0
			push_ui(self)
		end
	end
	session.update_balls(self, dt, push_ui, save_progress)
	debug_stats.draw(self.baskets, self.hits, self.total_hits, self.score)
end

function M.on_message(self, message_id, message, sender)
	if message_id == consts.MSG.DROP_BALL then
		session.drop_ball(self, push_ui, save_progress)
	elseif message_id == consts.MSG.DROP_MANY then
		session.drop_many(self, message and message.count, push_ui, save_progress)
	elseif message_id == consts.MSG.ADD_BALLS then
		self.economy:add(message and message.count)
		push_ui(self)
		save_progress(self)
	elseif message_id == consts.MSG.TOGGLE_SPEED then
		self.speed_x2 = not self.speed_x2
		push_ui(self)
	elseif message_id == consts.MSG.REQUEST_UI then
		push_ui(self)
	end
end

function M.on_input(self, action_id, action)
end

return M
