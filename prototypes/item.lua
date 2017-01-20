data:extend({
  {
    type = "item",
    name = "down-tunnel",
    icon = "__undergroundexpansion__/graphics/down-tunnel.png",
    flags = {"goes-to-quickbar"},
    subgroup = "production-machine",
    order = "y[tunnel]-a[down-tunnel]",
    place_result = "down-tunnel",
    stack_size = 10
  }
})

data:extend({
  {
    type = "item",
    name = "up-tunnel",
    icon = "__undergroundexpansion__/graphics/up-tunnel.png",
    flags = {"goes-to-quickbar"},
    subgroup = "production-machine",
    order = "y[tunnel]-a[up-tunnel]",
    place_result = "up-tunnel",
    stack_size = 10
  }
})