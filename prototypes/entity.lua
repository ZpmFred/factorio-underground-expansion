data:extend({{
	type = "simple-entity",
	name = "border-rock",
	render_layer = "resource",
	picture = {
		filename="__undergroundexpansion__/graphics/terrain/border-rock_32.png",
		width = 32,
		height = 32,
		shift = {0, 0}
	},
	max_health = 50,
    collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
	minable = {
		mining_time = 1
	},
	resistances = {
		{
			type = "fire",
			percent = 100
		}
	}

}})

local downTunnel = table.deepcopy(data.raw["lamp"]["small-lamp"])
table.merge(downTunnel, {
	name = "down-tunnel",
	icon = "__undergroundexpansion__/graphics/down-tunnel.png",
--	energy_usage_per_tick = "1KW",
--	light = {intensity = 0, size = 0},
	picture_off = {
		filename="__undergroundexpansion__/graphics/down-tunnel.png",
      	priority = "high",
		width = 64,
		height = 64,
		frame_count = 1,
		axially_symmetrical = false,
		direction_count = 1,
		shift = {0.01, 0.01},
	},
--	picture_on = {
--		filename="__undergroundexpansion__/graphics/down-tunnel.png",
--		width = 64,
--		height = 64,
--		shift = {0, 0}
--	}
})
downTunnel.minable.result = "down-tunnel"
data:extend({	downTunnel })

local upTunnel = table.deepcopy(data.raw["lamp"]["small-lamp"])
table.merge(upTunnel, {
	name = "up-tunnel",
	icon = "__undergroundexpansion__/graphics/up-tunnel.png",
	energy_usage_per_tick = "1KW",
	light = {intensity = 0, size = 0},
	picture_off = {
		filename="__undergroundexpansion__/graphics/up-tunnel.png",
		width = 64,
		height = 64,
		shift = {0, 0}
	},
	picture_on = {
		filename="__undergroundexpansion__/graphics/up-tunnel.png",
		width = 64,
		height = 64,
		shift = {0, 0}
	}
})
upTunnel.minable.result = "up-tunnel"
data:extend({	upTunnel })