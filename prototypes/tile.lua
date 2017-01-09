data:extend(
    {
        {
            type = "tile",
            name = "underground-rock",
            collision_mask =
            {
                "water-tile", --marking as "water-tile" so "stones" and "concrete" can not be placed on it.
                "floor-layer", --marking as "floor-layer" so "landfill" can not be placed on it, (landfill is modified by the modify script to add this condition)
                "item-layer",
                "resource-layer",
                "player-layer",
                "doodad-layer"
            },
            layer = 40,
            variants =
            {
                main =
                {
                    {
                        picture = "__undergroundexpension__/graphics/terrain/space1.png",
                        count = 16,
                        size = 1
                    },
                    {
                        picture = "__undergroundexpension__/graphics/terrain/space2.png",
                        count = 4,
                        size = 2,
                        probability = 0.39,
                    },
                    {
                        picture = "__undergroundexpension__/graphics/terrain/space4.png",
                        count = 4,
                        size = 4,
                        probability = 1,
                    },
                },
                inner_corner =
                {
                    picture = "__base__/graphics/terrain/out-of-map-inner-corner.png",
                    count = 0
                },
                outer_corner =
                {
                    picture = "__base__/graphics/terrain/out-of-map-outer-corner.png",
                    count = 0
                },
                side =
                {
                    picture = "__base__/graphics/terrain/out-of-map-side.png",
                    count = 0
                }
            },
            ageing = 0,
            map_color = {r = 87, g = 65, b = 47},
            mineable_properties = {
                minable = true,
                hardness = 1.0,
                miningtime = 1.0,
                products:[]
            }
        }
    }
)
