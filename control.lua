require("stdlib.table")
require("stdlib.string")
require("stdlib.area.area")
require("stdlib.area.position")
require("stdlib.area.tile")
require("stdlib.area.chunk")
require("stdlib.surface")

if not underexp then underexp = {} end
underexp.surfaceNameSeparator = "-underground-expansion-"
underexp.tunnelCaveSize = 4 -- number of tile to le left top botom and right ex: tunnelCaveSize = 2 ==> cave = 5X5

-- INIT
script.on_init( function()
    if not global then global = {} end
    if not global.underexp then global.underexp = {} end
    if not global.underexp.tunnels then global.underexp.tunnels = {} end
end)

-- CUSTOM CONTROL PLAYER ENTER TUNNEL
script.on_event("enter-tunnel", function(event)
    local player = game.players[event.player_index]
    local entity = player.selected

    -- player.print("---")
    -- player.print(Position.tostring(player.position))
    -- player.print(Position.tostring(entity.position))
    -- player.print("---")

    if entity and player and isTunnel(entity) and Position.distance(entity.position, player.position) < 3 then
        if isTunnelOutputAreaGenerated(entity) then
            if createTunnelCounterpart(entity) then
                player.teleport(player.position, getTunnelCounterpartSurface(entity))
            else
                player.print("Can't create tunnel counterpart. the destination is probably obstructed")
            end
        else
            player.print("Please wait currently mining tunnel")
        end
    end
end)

-- ON BUILD
script.on_event(defines.events.on_built_entity, function(event)
    if not checkForNewTunnel(event.created_entity) then
        local player = game.players[event.player_index]
        player.print("can't place upper tunnel when not underground")
    end
end)

-- ON ENTITY DIED
script.on_event(defines.events.on_entity_died, function(event)
    onTunnelDestroyed(event.entity)
    onBorderRockDestroyed(event.entity)
end)

-- ON PRE PLAYER MINED ITEM
script.on_event(defines.events.on_preplayer_mined_item, function(event)
    onTunnelPickup(event.entity)
    onBorderRockDestroyed(event.entity)
end)

-- ON CHUNK GENERATED
script.on_event(defines.events.on_chunk_generated, function(event)
    undergroundChunkGenerationEvent(event)
end)

-- ON TICK
script.on_event(defines.events.on_tick, function(event)
    if (game.tick % 60 == 0) then
        propagateTunnelPollutionUp()
    end
end)



-- ########################################################################
-- ######################### BORDER ROCK CONTROLS #########################
-- ########################################################################

function onBorderRockDestroyed(rock)
    if isBorderRock(rock) then
        local adjacentOutOfMap = Tile.adjacent(rock.surface, rock.position, true, "out-of-map")
        
        local tiles = {}
        for i, outPos in ipairs(adjacentOutOfMap) do
            table.insert(tiles, {name="underground-rock", position=outPos})
            rock.surface.create_entity{name = "border-rock", position = outPos, force = "neutral"}
        end
        rock.surface.set_tiles(tiles)

    end
end

function isBorderRock(entity)
    return entity.name == "border-rock"
end

-- ########################################################################
-- ######################### TUNNELS CONTROLS #############################
-- ########################################################################

-- propagate chunk pollution up
function propagateTunnelPollutionUp()
    for sti, surfaceTunnelName in pairs(global.underexp.tunnels) do
        for ti, tunnel in ipairs(surfaceTunnelName) do
            if isUpTunnel(tunnel) then
                local counterpartTunnel = getCounterpartTunnel(tunnel)
                local undergroundPollution = tunnel.surface.get_pollution(tunnel.position)

                -- transfer polution
                counterpartTunnel.surface.pollute(counterpartTunnel.position, undergroundPollution)
                tunnel.surface.pollute(tunnel.position, -undergroundPollution)
            end
        end 
    end
end

-- on tunnel pickup remove counterpart tunnel
function onTunnelPickup(tunnel)
    if isTunnel(tunnel) then
        removeTunnelFromGlobalList(tunnel)
        
        if isTunnelCounterpartGenerated(tunnel) then
            local counterpartTunnel = getCounterpartTunnel(tunnel)

            if counterpartTunnel then 
                removeTunnelFromGlobalList(counterpartTunnel)
                counterpartTunnel.destroy()
            end
        end
    end
end

-- when a tunnel is destroyed
function onTunnelDestroyed(tunnel) 
    if isTunnel(tunnel) then
        removeTunnelFromGlobalList(tunnel)

        if isTunnelCounterpartGenerated(tunnel) then
            local counterpartTunnel = getCounterpartTunnel(tunnel)

            if counterpartTunnel then 
                removeTunnelFromGlobalList(counterpartTunnel)
                counterpartTunnel.die()
            end
        end
    end
end

-- generating the surface beneath the down tunnel
function generateBelowChunkFromDownTunnel(entity)
    local surfaceName = getBelowSurfaceName(entity.surface.name)

    -- creation de la surface
    if not game.surfaces[surfaceName] then 
        createNewUndergroundSurface(surfaceName)
    end

    generateCaveChunk(game.surfaces[surfaceName], entity.position)
end

-- generating the surface above the up tunnel
function generateAboveChunkFromUpTunnel(entity)
    local surfaceName = getAboveSurfaceName(entity.surface.name)

    if surfaceName then
        generateCaveChunk(game.surfaces[surfaceName], entity.position)
    end
end

-- create the tunnel counterpart tunnel return false if the destination is obstructed
function createTunnelCounterpart(tunnel)
    local surface = getTunnelCounterpartSurface(tunnel)

    if surface and not isTunnelCounterpartGenerated(tunnel) then
        local tunnelEntityName = getCounterpartTunnelName(tunnel)

        if isSurfaceUnderground(surface) then
            createTunnelCave(surface, tunnel.position)
        end
        if surface.can_place_entity{name = tunnelEntityName, position = tunnel.position, force = "player"} then
            local tunnel = surface.create_entity{name = tunnelEntityName, position = tunnel.position, force = "player"}
            addTunnelToGlobalList(tunnel)
        else 
            return false
        end
    end

    return true
end

-- ########################################################################
-- ######################### TUNNELS UTILS ################################
-- ########################################################################

function isDownTunnel(entity)
    return entity.name == "down-tunnel"
end

function isUpTunnel(entity)
    return entity.name == "up-tunnel"
end

function isTunnel(entity)
    return isDownTunnel(entity) or isUpTunnel(entity)
end

function getCounterpartTunnelName(tunnel)
    if isDownTunnel(tunnel) then
        return "up-tunnel"
    elseif isUpTunnel(tunnel) then
        return "down-tunnel"
    end

    return nil 
end

function getCounterpartTunnel(tunnel)
    local counterpartSurface = getTunnelCounterpartSurface(tunnel)
    return counterpartSurface.find_entity(getCounterpartTunnelName(tunnel), tunnel.position)
end

function checkForNewTunnel(entity)
    if isDownTunnel(entity) then
        addTunnelToGlobalList(entity)
        generateBelowChunkFromDownTunnel(entity)
        return true
    elseif isUpTunnel(entity) then
        addTunnelToGlobalList(entity)
        if isSurfaceUnderground(entity.surface) then 
            generateAboveChunkFromUpTunnel(entity)
            return true
        else
            return false
        end
    end
end

-- check if the other side chunks of the tunnel has been generated 
function isTunnelOutputAreaGenerated(tunnel)
    local surface = getTunnelCounterpartSurface(tunnel)

    if surface then        
        local tunnelCaveDescriptor = getTunnelCaveDescriptor(tunnel.position)
        local caveArea = tunnelCaveDescriptor.outerCaveArea
        local areaSize = Area.offset(table.deepcopy(caveArea), {x = -caveArea.left_top.x, y = -caveArea.left_top.y}).right_bottom
        local allChunkGenerated = true

        for x=0, math.floor(areaSize.x / 32) do
            for y=0, math.floor(areaSize.y / 32) do
                local areaPos = table.deepcopy(tunnel.position)
                areaPos.x = math.floor(areaPos.x) + x * 32
                areaPos.y = math.floor(areaPos.y) + y * 32

                allChunkGenerated = allChunkGenerated and surface.is_chunk_generated(Chunk.from_position(areaPos))
            end
        end 
        return allChunkGenerated
    else
        return nil
    end
end

-- get the tunnel otherside surface
function getTunnelCounterpartSurface(tunnel)   
    local surface = nil
    if isDownTunnel(tunnel) then
        surface = getBelowSurface(tunnel.surface)
    elseif isUpTunnel(tunnel) then
        surface = getAboveSurface(tunnel.surface)
    end

    return surface
end

-- check if the tunnel has an counterpart tunnel
function isTunnelCounterpartGenerated(tunnel)
    local surface = getTunnelCounterpartSurface(tunnel)

    if surface then
        if isDownTunnel(tunnel) then
            return surface.find_entity("up-tunnel", tunnel.position)
        elseif isUpTunnel(tunnel) then
            return surface.find_entity("down-tunnel", tunnel.position)
        end
    end

    return false
end

-- add a tunnel to the global list of tunnel for the surface of the tunnel
function addTunnelToGlobalList(tunnel)
    if not global.underexp.tunnels[tunnel.surface.name] then 
        global.underexp.tunnels[tunnel.surface.name] = {};
    end
    table.insert(global.underexp.tunnels[tunnel.surface.name], tunnel);
end

-- remove a tunnel from the global list of tunnel for the surface of the tunnel
function removeTunnelFromGlobalList(tunnel)
    if global.underexp.tunnels[tunnel.surface.name] then
        for i, storedTunnel in ipairs(global.underexp.tunnels[tunnel.surface.name]) do
            if storedTunnel == tunnel then
                table.remove(global.underexp.tunnels[tunnel.surface.name], i)
                break
            end
        end
    end
end

-- ########################################################################
-- ######################### CAVE GENERATION ##############################
-- ########################################################################

-- generate chunk for a cave on a specified surface
function generateCaveChunk(surface, position)
    local tunnelCaveDescriptor = getTunnelCaveDescriptor(position)
    local caveArea = tunnelCaveDescriptor.outerCaveArea
    local areaSize = Area.offset(table.deepcopy(caveArea), {x = -caveArea.left_top.x, y = -caveArea.left_top.y}).right_bottom

    for x=0, math.floor(areaSize.x / 32) do
        for y=0, math.floor(areaSize.y / 32) do
            local areaPos = table.deepcopy(position)
            areaPos.x = areaPos.x + x * 32
            areaPos.y = areaPos.y + y * 32

            surface.request_to_generate_chunks(areaPos, 2)
        end
    end
end

-- create a cave on "surface" at "position"
function createTunnelCave(surface, position)
    local caveDescriptor = getTunnelCaveDescriptor(position)
    local tunnelCaveDescriptorList = getAboveAndBelowTunnelCaveDescriptorOverlappingArea(surface, caveDescriptor.outerCaveArea)

    -- for key, tunnelCaveDescriptor in ipairs(tunnelCaveDescriptorList) do
    --     game.print("inner left_top" .. Position.tostring(tunnelCaveDescriptor.innerCaveArea["left_top"]))
    --     game.print("inner right_bottom" .. Position.tostring(tunnelCaveDescriptor.innerCaveArea["right_bottom"]))
    --     game.print("outer left_top" .. Position.tostring(tunnelCaveDescriptor.outerCaveArea["left_top"]))
    --     game.print("outer right_bottom" .. Position.tostring(tunnelCaveDescriptor.outerCaveArea["right_bottom"]))
    -- end

    -- clean cave walls
    for i, rock in ipairs(Surface.find_all_entities({name = "border-rock", surface = surface.name, area = caveDescriptor.innerCaveArea})) do
        rock.destroy()
    end

    -- generate cave tile
    local tiles = {}
    for x=caveDescriptor.outerCaveArea.left_top.x, caveDescriptor.outerCaveArea.right_bottom.x do
        for y=caveDescriptor.outerCaveArea.left_top.y, caveDescriptor.outerCaveArea.right_bottom.y do
            local pos = {x, y}

            -- si on doit metre un rock tile
            if table.any(tunnelCaveDescriptorList, function (v, k, pos) return isTunnelCaveDescriptorRockTile(v, pos) end, pos) then
                table.insert(tiles, {name="underground-rock", position=pos})
            end

            local entity = surface.find_entity("border-rock", pos)
            local isRockBorder = false
            local isRockTileAlone = false

            -- entity type of this tile
            for key, tunnelCaveDescriptor in ipairs(tunnelCaveDescriptorList) do
                isRockTileAlone = isRockTileAlone or (
                    isTunnelCaveDescriptorRockTile(tunnelCaveDescriptor, pos) 
                    and not isTunnelCaveDescriptorRockBorder(tunnelCaveDescriptor, pos)
                )

                isRockBorder = isRockBorder or (
                    isTunnelCaveDescriptorRockTile(tunnelCaveDescriptor, pos) 
                    and isTunnelCaveDescriptorRockBorder(tunnelCaveDescriptor, pos)
                )
            end

            -- rock creation
            if isRockBorder and not isRockTileAlone and isTileAdjacentToOutOfMap(surface, pos) then
                -- game.print("rock: " .. Position.tostring(pos))
                -- game.print(Area.tostring(event.area))
                surface.create_entity{name = "border-rock", position = pos, force = "neutral"}
            end
        end
    end
    surface.set_tiles(tiles)
end

function isTileAdjacentToOutOfMap(surface, position) 
    local adjacentTilePosList = Tile.adjacent(surface, position, true, "out-of-map")

    return #adjacentTilePosList > 0
end

-- ########################################################################
-- ######################### SURFACE UTILS ################################
-- ########################################################################

-- get if the surface is un underground
function isSurfaceUnderground(surface)
    return isUndergroundSurfaceName(surface.name)
end

function getAboveSurface(surface)
    local aboveSurfaceName = getAboveSurfaceName(surface.name)
    if aboveSurfaceName then
        return game.surfaces[aboveSurfaceName]
    end

    return nil
end

function getBelowSurface(surface)
    local belowSurfaceName = getBelowSurfaceName(surface.name)
    if belowSurfaceName then
        return game.surfaces[belowSurfaceName]
    end

    return nil
end


-- ########################################################################
-- ######################### SURFACE NAME UTILS ###########################
-- ########################################################################

function isUndergroundSurfaceName(surfaceName)
    return string.contains(surfaceName, underexp.surfaceNameSeparator)
end

-- get main surface name
function getMainSurfaceName(surfaceName)
    if isUndergroundSurfaceName(surfaceName) then
        return surfaceName:split(underexp.surfaceNameSeparator)[1]
    end

    return nil 
end

-- get the underground layer of the give surface or 0 if the surface is not an underground one
function getUndergroundSurfaceNameLayerNumber(surfaceName)
    if isUndergroundSurfaceName(surfaceName) then
        return tonumber(surfaceName:split(underexp.surfaceNameSeparator)[2])
    else
        return 0;
    end
end

-- get the underground surface name linked to the surface name for the given layer 
function getUndergroundSurfaceNameForLayer(surfaceName, layer)
    if isUndergroundSurfaceName(surfaceName) then
        return getMainSurfaceName(surfaceName) .. underexp.surfaceNameSeparator .. layer
    else
        return surfaceName .. underexp.surfaceNameSeparator .. layer
    end
end

-- get the above surface name
function getAboveSurfaceName(surfaceName)
    if isUndergroundSurfaceName(surfaceName) then
        local layerNumber = getUndergroundSurfaceNameLayerNumber(surfaceName)

        -- deep in the underground
        if layerNumber > 1 then
            return getUndergroundSurfaceNameForLayer(surfaceName, getUndergroundSurfaceNameLayerNumber(surfaceName) - 1)
        -- layer just below the surface
        else
            return getMainSurfaceName(surfaceName)
        end
    end

    return nil 
end

-- get the below surface name
function getBelowSurfaceName(surfaceName)
    if isUndergroundSurfaceName(surfaceName) then
        return getUndergroundSurfaceNameForLayer(surfaceName, getUndergroundSurfaceNameLayerNumber(surfaceName) + 1)
    else
        return getUndergroundSurfaceNameForLayer(surfaceName, 1)
    end
end

-- ########################################################################
-- ########################### TUNNELS UTILS ##############################
-- ########################################################################

function getTunnelCaveDescriptorOverlappingArea(surfaceName, area) 
    -- expanding area to take in account the rock border
    local tunnelSearchArea = Area.expand(area, underexp.tunnelCaveSize + 2) -- +1 for the tunnel entity +1 for the border

    -- get the tunnels in the given area
    local tunnelCaveDescriptorList = {}
    for i, tunnel in ipairs(Surface.find_all_entities({name = "down-tunnel", surface = surfacename, area = tunnelSearchArea})) do
        local tunnelCaveDescriptor = getTunnelCaveDescriptor(tunnel.position)
        tunnelCaveDescriptor.isDownTunnel = true
        table.insert(tunnelCaveDescriptorList, tunnelCaveDescriptor)
    end

    for i, tunnel in ipairs(Surface.find_all_entities({name = "up-tunnel", surface = surfacename, area = tunnelSearchArea})) do
        local tunnelCaveDescriptor = getTunnelCaveDescriptor(tunnel.position)
        tunnelCaveDescriptor.isDownTunnel = false
        table.insert(tunnelCaveDescriptorList, tunnelCaveDescriptor)
    end

    return tunnelCaveDescriptorList
end

function getTunnelCaveDescriptor(pos)
    local tunnelCaveDescriptor = {}
    tunnelCaveDescriptor.tunnelPos = pos
    tunnelCaveDescriptor.isDownTunnel = nil
    tunnelCaveDescriptor.innerCaveArea = Area.expand(Area.construct(math.floor(pos.x), math.floor(pos.y), math.floor(pos.x), math.floor(pos.y)), underexp.tunnelCaveSize)
    tunnelCaveDescriptor.outerCaveArea = Area.expand(tunnelCaveDescriptor.innerCaveArea, 1)

    return tunnelCaveDescriptor
end

function isTunnelCaveDescriptorRockBorder(tunnelCaveDescriptor, pos)
    return Area.inside(tunnelCaveDescriptor.outerCaveArea, pos) and not Area.inside(tunnelCaveDescriptor.innerCaveArea, pos)
end

function isTunnelCaveDescriptorRockTile(tunnelCaveDescriptor, pos)
    return Area.inside(tunnelCaveDescriptor.outerCaveArea, pos)
end

function isTunnelCaveDescriptorTunnel(tunnelCaveDescriptor, pos)
    return Position.equals(tunnelCaveDescriptor.tunnelPos, pos) 
end


-- ########################################################################
-- ########################### MAP GENERATION #############################
-- ########################################################################

-- create a new underground surface if it does not already exist
function createNewUndergroundSurface(surfaceName)
    if not game.surfaces[surfaceName] then 
        local settings = {
            terrain_segmentation="none",
            water="none",
            
            autoplace_controls={},
            width=0,
            height=0,
            starting_area="none",
            peaceful_mode=true,
        }
        local autoplace_controls = {"iron-ore", "copper-ore", "stone", "coal", "crude-oil", "enemy-base"}
        for name, value in ipairs(autoplace_controls) do
            settings.autoplace_controls[name]={frequency="none",size="none",richness="none"}
        end
        game.create_surface(surfaceName, settings)
        game.surfaces[surfaceName].freeze_daytime(true)
        game.surfaces[surfaceName].daytime = 0.5
    end
end

-- generating chunk for the undergroud surface
function undergroundChunkGenerationEvent(event) 
    -- generating only underground surfaces
    if not isSurfaceUnderground(event.surface) then return end

    -- clear all the entity
    for i, entity in ipairs(event.surface.find_entities(event.area)) do
        if entity.type ~= "player" then
            entity.destroy()
        end
    end

    -- fill the chuck tiles
    local tiles = {}
    for x=event.area.left_top.x - 1, event.area.right_bottom.x do
        for y=event.area.left_top.y - 1, event.area.right_bottom.y do
            local pos = {x, y}
            table.insert(tiles, {name="out-of-map", position=pos})
        end
    end
    event.surface.set_tiles(tiles)

end

function getAboveAndBelowTunnelCaveDescriptorOverlappingArea(currentSurface, area)
    local aboveSurface = getAboveSurface(currentSurface)
    local belowSurface = getBelowSurface(currentSurface)
    local tunnelCaveDescriptorList = {}


    -- for the above surface only keep down tunnels
    if aboveSurface then
        local aboveTunnelCaveDescriptionList = getTunnelCaveDescriptorOverlappingArea(aboveSurface.name, area)
        aboveTunnelCaveDescriptionList = table.filter(aboveTunnelCaveDescriptionList, function(v) return v.isDownTunnel end)
        tunnelCaveDescriptorList = table.merge(tunnelCaveDescriptorList, aboveTunnelCaveDescriptionList, true)
    end
    
    -- for the below surface only keep up tunnels
    if belowSurface then
        local belowTunnelCaveDescriptionList = getTunnelCaveDescriptorOverlappingArea(belowSurface.name, area)
        belowTunnelCaveDescriptionList = table.filter(belowTunnelCaveDescriptionList, function(v) return not v.isDownTunnel end)
        tunnelCaveDescriptorList = table.merge(tunnelCaveDescriptorList, belowTunnelCaveDescriptionList, true)
    end

    return tunnelCaveDescriptorList
end