local signal = require "ludobits.m.signal"
local save_data = require "common.save_data"

local M = {}

local SOUND_KEY = "sound"
local is_sound_on = true

M.state_changed = signal.create("state_changed")

local sounds = {
	background = msg.url("main:/sounds#background"),
	button = msg.url("main:/sounds#button"),
	ping = msg.url("main:/sounds#ping"),
}

local function play(sound_id, complete)
	if is_sound_on and sound_id then
		sound.play(sound_id, nil, complete)
		return true
	end
end

function M.initialize()
	local saved = save_data.load(SOUND_KEY)
	if saved == nil then
		is_sound_on = true
	else
		is_sound_on = saved and true or false
	end
	if is_sound_on then
		sound.play(sounds.background)
	end
end

function M.get_sound_state()
	return is_sound_on
end

function M.change_sound_state()
	is_sound_on = not is_sound_on
	if is_sound_on then
		sound.play(sounds.background)
	else
		sound.stop(sounds.background)
	end
	save_data.save(SOUND_KEY, is_sound_on)
	M.state_changed.trigger({ sound = is_sound_on })
end

function M.play_button()
	play(sounds.button)
end

function M.play_ping()
	play(sounds.ping)
end

return M
