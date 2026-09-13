local consts = require "common.consts"

local M = {}

function M.for_weight(weight, min_w, max_w)
	local lo = consts.BASKET_TINT.WEIGHT_LOW
	local hi = consts.BASKET_TINT.WEIGHT_HIGH
	local t = 0.5
	if max_w > min_w then
		t = (weight - min_w) / (max_w - min_w)
	end
	return vmath.vector4(
		lo.x + (hi.x - lo.x) * t,
		lo.y + (hi.y - lo.y) * t,
		lo.z + (hi.z - lo.z) * t,
		1
	)
end

function M.weight_range(baskets)
	local min_w, max_w
	for _, b in ipairs(baskets or {}) do
		local w = b.weight or 0
		if not min_w or w < min_w then
			min_w = w
		end
		if not max_w or w > max_w then
			max_w = w
		end
	end
	return min_w or 0, max_w or 0
end

return M
