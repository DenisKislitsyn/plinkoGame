local level_mod = require "common.level"
local board_layout = require "common.board_layout"
local camera_utils = require "common.camera_utils"
local basket_tint = require "common.basket_tint"
local default_style = require "druid.styles.default.style"

local M = {}

local PIN_TINT = {
	[true] = vmath.vector4(1),
	[false] = vmath.vector4(1, 1, 1, 0.4)
}
local FIELD_OFFSET_Y = 60

local HASH_PIN = hash("pin_tpl")
local HASH_BASKET = hash("basket_tpl")
local HASH_WEIGHT = hash("weight_text")
local HASH_POINTS = hash("points_text")
local HASH_W_PLUS = hash("w_plus_btn")
local HASH_W_MINUS = hash("w_minus_btn")
local HASH_P_PLUS = hash("p_plus_btn")
local HASH_P_MINUS = hash("p_minus_btn")
local HASH_BODY = hash("basket_body")

local silent_button = {}
for k, v in pairs(default_style.button) do
	silent_button[k] = v
end
silent_button.on_hover = function() end
silent_button.on_mouse_hover = function() end
silent_button.on_click = function() end
silent_button.on_set_enabled = function() end

local function clear_dynamic(self)
	if self.pin_buttons then
		for _, btn in ipairs(self.pin_buttons) do
			self.druid:remove(btn)
		end
	end
	if self.weight_buttons then
		for _, btn in ipairs(self.weight_buttons) do
			self.druid:remove(btn)
		end
	end
	if self.score_buttons then
		for _, btn in ipairs(self.score_buttons) do
			self.druid:remove(btn)
		end
	end
	if self.pin_roots then
		for _, node in ipairs(self.pin_roots) do
			gui.delete_node(node)
		end
	end
	if self.basket_roots then
		for _, node in ipairs(self.basket_roots) do
			gui.delete_node(node)
		end
	end
	self.pin_buttons = {}
	self.weight_buttons = {}
	self.score_buttons = {}
	self.pin_roots = {}
	self.basket_roots = {}
	self.pin_nodes = {}
	self.weight_texts = {}
	self.score_texts = {}
	self.basket_bodies = {}
	self.slots = nil
end

local function to_gui(x, y)
	return x, y + FIELD_OFFSET_Y
end

local function set_pin_tint(node, active)
	gui.set_color(node, PIN_TINT[active])
end

local function bind_stepper(self, plus_node, minus_node, on_plus, on_minus, store)
	local plus = self.druid:new_button(plus_node, on_plus)
	local minus = self.druid:new_button(minus_node, on_minus)
	plus.on_repeated_click:subscribe(on_plus)
	minus.on_repeated_click:subscribe(on_minus)
	store[#store + 1] = plus
	store[#store + 1] = minus
end

local function apply_basket_colors(self)
	local min_w, max_w = basket_tint.weight_range(self.draft.baskets)
	for i, body in ipairs(self.basket_bodies or {}) do
		local b = self.draft.baskets[i]
		if b and body then
			gui.set_color(body, basket_tint.for_weight(b.weight or 0, min_w, max_w))
		end
	end
end

function M.init(self)
	self.pin_tpl = gui.get_node("pin_tpl")
	self.basket_tpl = gui.get_node("basket_tpl")
	self.board = gui.get_node("board")
	self.basket_add_btn = gui.get_node("basket_add_btn")
	self.basket_remove_btn = gui.get_node("basket_remove_btn")
	gui.set_enabled(self.pin_tpl, false)
	gui.set_enabled(self.basket_tpl, false)
	gui.set_enabled(self.basket_remove_btn, true)
	gui.set_enabled(self.basket_add_btn, true)
	clear_dynamic(self)
end

function M.final(self)
	clear_dynamic(self)
end

function M.rebuild(self, on_pin_toggle, on_weight, on_score)
	clear_dynamic(self)

	local draft = self.draft
	local field = board_layout.build_editor_field(draft, camera_utils.design_bounds())
	self.slots = field.slots

	for i, slot in ipairs(field.slots) do
		local nodes = gui.clone_tree(self.pin_tpl)
		local root = nodes[HASH_PIN]
		gui.set_enabled(root, true)
		gui.set_parent(root, self.board)
		local gx, gy = to_gui(slot.x, slot.y)
		gui.set_position(root, vmath.vector3(gx, gy, 0))
		set_pin_tint(root, slot.active)
		self.pin_roots[#self.pin_roots + 1] = root
		self.pin_nodes[i] = root

		local btn = self.druid:new_button(root, function()
			on_pin_toggle(i)
		end)
		btn:set_style(silent_button)
		self.pin_buttons[#self.pin_buttons + 1] = btn
	end

	local min_w, max_w = basket_tint.weight_range(draft.baskets)

	for i, bslot in ipairs(field.baskets) do
		local nodes = gui.clone_tree(self.basket_tpl)
		local root = nodes[HASH_BASKET]
		local body = nodes[HASH_BODY]
		local weight_text = nodes[HASH_WEIGHT]
		local points_text = nodes[HASH_POINTS]
		local w_plus_btn = nodes[HASH_W_PLUS]
		local w_minus_btn = nodes[HASH_W_MINUS]
		local p_plus_btn = nodes[HASH_P_PLUS]
		local p_minus_btn = nodes[HASH_P_MINUS]

		gui.set_enabled(root, true)
		gui.set_parent(root, self.board)

		local gx, gy = to_gui(bslot.x, bslot.y)
		gui.set_position(root, vmath.vector3(gx, gy, 0))
		gui.set_size_mode(body, gui.SIZE_MODE_MANUAL)
		gui.set_size(body, vmath.vector3(bslot.width, bslot.height, 0))
		gui.set_color(body, basket_tint.for_weight(bslot.weight or 0, min_w, max_w))

		gui.set_text(weight_text, string.format("%d", bslot.weight or 1))
		gui.set_text(points_text, string.format("%d", bslot.score or 10))
		self.weight_texts[i] = weight_text
		self.score_texts[i] = points_text
		self.basket_bodies[i] = body

		local function bump_weight(delta)
			on_weight(i, delta)
		end
		bind_stepper(self, w_plus_btn, w_minus_btn, function()
			bump_weight(level_mod.weight_step())
		end, function()
			bump_weight(-level_mod.weight_step())
		end, self.weight_buttons)

		local function bump_score(delta)
			on_score(i, delta)
		end
		bind_stepper(self, p_plus_btn, p_minus_btn, function()
			bump_score(level_mod.score_step())
		end, function()
			bump_score(-level_mod.score_step())
		end, self.score_buttons)

		self.basket_roots[#self.basket_roots + 1] = root
	end
end

function M.refresh_pin_tints(self)
	if not self.slots or not self.pin_nodes then
		return
	end
	for i, slot in ipairs(self.slots) do
		local node = self.pin_nodes[i]
		if node then
			set_pin_tint(node, slot.active)
		end
	end
end

function M.refresh_weights(self)
	for i, node in ipairs(self.weight_texts or {}) do
		local b = self.draft.baskets[i]
		if b and node then
			gui.set_text(node, string.format("%d", b.weight or 1))
		end
	end
	apply_basket_colors(self)
end

function M.refresh_scores(self)
	for i, node in ipairs(self.score_texts or {}) do
		local b = self.draft.baskets[i]
		if b and node then
			gui.set_text(node, string.format("%d", b.score or 10))
		end
	end
end

function M.commit_layout(self)
	if self.slots then
		self.draft.layout = board_layout.layout_from_slots(self.slots)
	end
end

return M
