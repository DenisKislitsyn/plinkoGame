local consts = require "common.consts"

local M = {}

M.CAMERA_URL = msg.url("main", "/camera", "camera")
M.SCRIPT_URL = msg.url("main", "/camera", "script")

function M.design_bounds()
	local hw = consts.DISPLAY_WIDTH * 0.5
	local hh = consts.DISPLAY_HEIGHT * 0.5
	return vmath.vector4(-hw, hh, hw, -hh)
end

function M.screen_to_world_bounds()
	local w, h = window.get_size()
	local bottom_left = camera.screen_xy_to_world(0, 0, M.CAMERA_URL)
	local top_right = camera.screen_xy_to_world(w, h, M.CAMERA_URL)
	return vmath.vector4(bottom_left.x, top_right.y, top_right.x, bottom_left.y)
end

function M.world_to_screen(x, y)
	return camera.world_to_screen(vmath.vector3(x, y, 0), M.CAMERA_URL)
end

function M.shake(intensity, duration)
	msg.post(M.SCRIPT_URL, consts.MSG.SHAKE, {
		intensity = intensity,
		duration = duration,
	})
end

return M
