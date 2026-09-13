local default = require "druid.styles.default.style"
local sounds = require "common.sounds"

local HASH_NORMAL = hash("btn_green_normal")
local HASH_PUSH = hash("btn_green_push")

local M = {}
for k, v in pairs(default) do
	M[k] = v
end

local button = {}
for k, v in pairs(default.button) do
	button[k] = v
end

button.on_hover = function(self, node, state)
	gui.play_flipbook(node, state and HASH_PUSH or HASH_NORMAL)
end

button.on_mouse_hover = function(self, node, state)
	-- No scale / sprite change on mouse hover.
end

button.on_click = function(self, node)
	gui.play_flipbook(node, HASH_NORMAL)
	sounds.play_button()
end

M.button = button

return M
