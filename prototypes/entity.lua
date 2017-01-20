local downTunnel = table.deepcopy(data.raw["lamp"]["small-lamp"])
table.merge(downTunnel, {
	name = "down-tunnel",
	icon = "__undergroundexpansion__/graphics/down-tunnel.png",
	energy_usage_per_tick = "1KW",
	light = {intensity = 0, size = 0},
	picture_off = {
		filename="__undergroundexpansion__/graphics/down-tunnel.png",
		width = 64,
		height = 64,
		shift = {0, 0}
	},
	picture_on = {
		filename="__undergroundexpansion__/graphics/down-tunnel.png",
		width = 64,
		height = 64,
		shift = {0, 0}
	}
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