return {
	version = 1,
	baskets = {
		{ id = 1,  weight = 1.00, score = 10 },
		{ id = 2,  weight = 2.00, score = 20 },
		{ id = 3,  weight = 3.00, score = 40 },
		{ id = 4,  weight = 4.00, score = 60 },
		{ id = 5,  weight = 5.00, score = 80 },
		{ id = 6,  weight = 5.00, score = 80 },
		{ id = 7,  weight = 4.00, score = 60 },
		{ id = 8,  weight = 3.00, score = 40 },
		{ id = 9,  weight = 2.00, score = 20 },
		{ id = 10, weight = 1.00, score = 10 },
	},
	-- Empty → pyramid layout built at load from design_bounds.
	layout = {},
	game = {
		balls_start = 10,
		regen_one_ball_seconds = 5,
		balls_regen_cap = 20,
		cheat_add_balls = 10,
		drop_many_count = 5,
		drop_many_spawn_interval_seconds = 0.05,
	},
}
