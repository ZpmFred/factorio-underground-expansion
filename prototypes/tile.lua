data:extend(
    {
        {
            type = "tile",
            name = "underground-rock",
            collision_mask = {"ground-tile"},
            layer = 36,
            variants =
            {
                main =
                {
                    {
                        picture = "__undergroundexpansion__/graphics/terrain/underground-rock/underground-rock1.png",
                        count = 16,
                        size = 1
                    },
                    {
                        picture = "__undergroundexpansion__/graphics/terrain/underground-rock/underground-rock2.png",
                        count = 16,
                        size = 2,
                        probability = 0.39,
                        weights = {0.025, 0.010, 0.013, 0.025, 0.025, 0.100, 0.100, 0.005, 0.010, 0.010, 0.005, 0.005, 0.001, 0.015, 0.020, 0.020}
                    },
                    {
                        picture = "__undergroundexpansion__/graphics/terrain/underground-rock/underground-rock4.png",
                        count = 22,
                        line_length = 11,
                        size = 4,
                        probability = 1,
                        weights = {0.090, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.025, 0.125, 0.005, 0.010, 0.100, 0.100, 0.010, 0.020, 0.020, 0.010, 0.100, 0.025, 0.100, 0.100, 0.100}
                    },
                },
                inner_corner =
                {
                    picture = "__undergroundexpansion__/graphics/terrain/underground-rock/underground-rock-inner-corner.png",
                    count = 8
                },
                outer_corner =
                {
                    picture = "__undergroundexpansion__/graphics/terrain/underground-rock/underground-rock-outer-corner.png",
                    count = 8
                },
                side =
                {
                    picture = "__undergroundexpansion__/graphics/terrain/underground-rock/underground-rock-side.png",
                    count = 8
                }
            },
            walking_sound =
            {
                {
                    filename = "__base__/sound/walking/sand-01.ogg",
                    volume = 0.8
                },
                {
                    filename = "__base__/sound/walking/sand-02.ogg",
                    volume = 0.8
                },
                {
                    filename = "__base__/sound/walking/sand-03.ogg",
                    volume = 0.8
                },
                {
                    filename = "__base__/sound/walking/sand-04.ogg",
                    volume = 0.8
                }
            },
            map_color={r=139, g=104, b=39},
        }
    }
)
