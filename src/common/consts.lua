return {
	DISPLAY_WIDTH = tonumber(sys.get_config_string("display.width")) or 720,
	DISPLAY_HEIGHT = tonumber(sys.get_config_string("display.height")) or 1280,

	PROP = {
		SIZE = "size",
		SCALE = "scale",
		TINT = "tint",
	},

	MSG = {
		INIT = hash("init_msg"),
		SHAKE = hash("shake"),
		DROP_BALL = hash("drop_ball"),
		DROP_MANY = hash("drop_many"),
		ADD_BALLS = hash("add_balls"),
		TOGGLE_SPEED = hash("toggle_speed"),
		UI_UPDATE = hash("ui_update"),
		REQUEST_UI = hash("request_ui"),
		PIN_HIT = hash("pin_hit"),
		ENABLE = hash('enable'),
		DISABLE = hash('disable'),
	},

	URL = {
		BG = "main:/go#background",
		BASKET_FACTORY = "game:/factories#basket_factory",
		PIN_FACTORY = "game:/factories#pin_factory",
		BALL_FACTORY = "game:/factories#ball_factory",
		HOLE_FACTORY = "game:/factories#hole_factory",
		GAME_SCRIPT = "game:/script#game",
		GAME_GUI = "game:/go#monarch",
	},

	BOARD = {
		BASKET_WIDTH = 50, -- fallback when slot width unknown
		BASKET_HEIGHT = 100,
		BASKET_GAP = 3, -- edge-to-edge gap between adjacent baskets
		BASKET_Y_FROM_BOTTOM = 300,
		MARGIN_X = 60,
		BASKET_Z = 0.1,

		PIN_Z = 0.1,
		PIN_Y_ABOVE_BASKET = 90,
		PIN_ROW_SPACING = 70,

		HOLE_Z = 0.05,
		HOLE_Y_ABOVE_TOP_PIN = 80,

		BALL_Z = 0.2,
		BALL_SPAWN_JITTER_X = 8,
	},

	BASKET_TINT = {
		WEIGHT_LOW = vmath.vector4(0.93, 0.68, 0.66, 1),
		WEIGHT_HIGH = vmath.vector4(0.62, 0.86, 0.72, 1),
	},
}
