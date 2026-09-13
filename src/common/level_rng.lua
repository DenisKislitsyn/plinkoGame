-- Level RNG: weighted pick + editor simulate.

local M = {}

function M.total_weight(baskets)
	local sum = 0
	for _, b in ipairs(baskets or {}) do
		sum = sum + (b.weight or 0)
	end
	return sum
end

function M.pick_by_weight(baskets, rnd)
	local t = M.total_weight(baskets)
	assert(t > 0, "baskets weights sum must be > 0")
	local r = rnd * t
	local acc = 0
	for _, b in ipairs(baskets) do
		acc = acc + (b.weight or 0)
		if r < acc then
			return b
		end
	end
	return baskets[#baskets]
end

--- Instant RNG sim for editor (no GO).
function M.simulate(baskets, count)
	count = count or 1000
	local hits = {}
	for _, b in ipairs(baskets) do
		hits[b.id] = 0
	end
	for _ = 1, count do
		local b = M.pick_by_weight(baskets, math.random())
		hits[b.id] = hits[b.id] + 1
	end
	local sum_w = M.total_weight(baskets)
	local rows = {}
	for i, b in ipairs(baskets) do
		local actual = hits[b.id] or 0
		rows[i] = {
			id = b.id,
			weight = b.weight,
			expected_pct = sum_w > 0 and (100 * b.weight / sum_w) or 0,
			actual_pct = count > 0 and (100 * actual / count) or 0,
			hits = actual,
		}
	end
	return rows, count
end

return M
