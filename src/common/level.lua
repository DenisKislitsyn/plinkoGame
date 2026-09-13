-- Level facade: schema + rng + edit. Prefer requiring submodules directly when possible.

local schema = require "common.level_schema"
local rng = require "common.level_rng"
local edit = require "common.level_edit"

local M = {}

M.weight_step = schema.weight_step
M.score_step = schema.score_step
M.composition_key = schema.composition_key
M.normalize = schema.normalize
M.default_from_configs = schema.default_from_configs

M.total_weight = rng.total_weight
M.pick_by_weight = rng.pick_by_weight
M.simulate = rng.simulate

M.row_count = edit.row_count
M.rebuild_layout = edit.rebuild_layout
M.add_basket = edit.add_basket
M.remove_basket = edit.remove_basket
M.adjust_weight = edit.adjust_weight
M.adjust_score = edit.adjust_score

return M
