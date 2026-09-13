local camera_utils = require "common.camera_utils"
local consts = require "common.consts"

local M = {}

local DRAW_TEXT = hash("draw_text")
local RENDER = "@render:"

local CHAR_W = 8
local LINE_H = 14
local BELOW_GAP = 6

local cache = {
	baskets = nil,
	slots = nil,
	lines = nil,
	dirty = true,
	win_w = 0,
	win_h = 0,
}

local function post_line(text, screen_x, screen_y)
	msg.post(RENDER, DRAW_TEXT, {
		text = text,
		position = vmath.vector3(screen_x - (#text * CHAR_W * 0.5), screen_y, 0),
	})
end

local function window_size()
	local w, h = window.get_size()
	return w, h
end

local function rebuild_positions(baskets)
	local y_below = consts.BOARD.BASKET_HEIGHT * 0.5 + BELOW_GAP
	local slots = {}
	for i, b in ipairs(baskets) do
		local screen = camera_utils.world_to_screen(b.x, b.y - y_below)
		slots[i] = {
			x = screen.x,
			y = screen.y,
			score = b.score,
			id = b.id,
		}
	end
	cache.baskets = baskets
	cache.slots = slots
	cache.dirty = true
	cache.win_w, cache.win_h = window_size()
end

local function rebuild_lines(hits, total_hits, total_score)
	hits = hits or {}
	total_hits = total_hits or 0
	local slots = cache.slots
	local lines = {}
	for i, s in ipairs(slots) do
		local h = hits[s.id] or 0
		local pct = total_hits > 0 and (100 * h / total_hits) or 0
		lines[i] = {
			string.format("%d/%d", h, total_hits),
			tostring(s.score),
			string.format("%.0f%%", pct),
		}
	end
	cache.lines = lines
	cache.total_score_text = string.format("Score: %d", total_score or 0)
	cache.dirty = false
end

function M.mark_dirty()
	cache.dirty = true
end

function M.set_baskets(baskets)
	if not baskets then
		cache.baskets = nil
		cache.slots = nil
		cache.lines = nil
		cache.total_score_text = nil
		cache.dirty = true
		return
	end
	rebuild_positions(baskets)
end

--- @param baskets table[]
--- @param hits table
--- @param total_hits number
--- @param total_score number player score (TZ debug)
function M.draw(baskets, hits, total_hits, total_score)
	if not baskets then
		return
	end

	local win_w, win_h = window_size()
	if cache.baskets ~= baskets or not cache.slots
		or win_w ~= cache.win_w or win_h ~= cache.win_h then
		rebuild_positions(baskets)
	end

	if cache.dirty or not cache.lines then
		rebuild_lines(hits, total_hits, total_score)
	end

	local slots = cache.slots
	local lines = cache.lines
	for i = 1, #slots do
		local s = slots[i]
		local L = lines[i]
		local x, y = s.x, s.y
		post_line(L[1], x, y)
		post_line(L[2], x, y - LINE_H)
		post_line(L[3], x, y - LINE_H * 2)
	end

	-- Total score once (TZ), centered above basket stats.
	if cache.total_score_text and #slots > 0 then
		local mid_x = (slots[1].x + slots[#slots].x) * 0.5
		post_line(cache.total_score_text, mid_x, slots[1].y - LINE_H * 4)
	end
end

return M
