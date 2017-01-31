require("stdlib.table")
require("stdlib.string")
require("stdlib.area.area")
require("stdlib.area.position")
require("stdlib.area.tile")
require("stdlib.area.chunk")
require("stdlib.surface")

if not global then global = {} end
if not global.underexp then global.undexexp = {} end

if not underexp then underexp = {} end
underexp.surfaceNameSeparator = "-underground-expansion-"
underexp.tunnelCaveSize = 1 -- number of tile to le left top botom and right ex: tunnelCaveSize = 2 ==> cave = 5X5

script.on_event("enter-tunnel", function(event)
    local player = game.players[event.player_index]
    local entity = player.selected

    player.print("---")
    player.print(Position.tostring(player.position))
    player.print(Position.tostring(entity.position))
    player.print("---")

    if entity and isTunnel(entity) and Position.distance(entity.position, player.position) < 3 then
        if isTunnelOutputChunkGenerated(entity) then
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

script.on_event(defines.events.on_built_entity, function(event)
    game.players[event.player_index].print(Position.tostring(event.created_entity.position))

    if not checkForNewTunnel(event.created_entity) then
        local player = game.players[event.player_index]
        player.print("can't place upper tunnel when not underground")
    end
end)

script.on_event(defines.events.on_chunk_generated, function(event)
    undergroundChunkGenerationEvent(event)
end)





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

function checkForNewTunnel(entity)
    if isDownTunnel(entity) then
        generateBelowChunkFromDownTunnel(entity)
        return true
    elseif isUpTunnel(entity) then
        if isSurfaceUnderground(entity.surface) then 
            generateAboveChunkFromUpTunnel(entity)
            return true
        else
            return false
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

    -- generation du chunk
    game.surfaces[surfaceName].request_to_generate_chunks(entity.position, 2)
end

-- generating the surface above the up tunnel
function generateAboveChunkFromUpTunnel(entity)
    local surfaceName = getAboveSurfaceName(entity.surface.name)

    if surfaceName then

        -- generation du chunk
        game.surfaces[surfaceName].request_to_generate_chunks(entity.position, 2)
    end
end

-- check if the other side chunk of the tunnel has been generated 
function isTunnelOutputChunkGenerated(tunnel)
    local surface = getTunnelCounterpartSurface(tunnel)

    if surface then
        return surface.is_chunk_generated(Chunk.from_position(tunnel.position))
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

-- create the tunnel counterpart tunnel return false if the destination is obstructed
function createTunnelCounterpart(tunnel)
    local surface = getTunnelCounterpartSurface(tunnel)

    if surface and not isTunnelCounterpartGenerated(tunnel) then
        local tunnelEntityName = nil
        if isDownTunnel(tunnel) then
            tunnelEntityName = "up-tunnel"
        elseif isUpTunnel(tunnel) then
            tunnelEntityName = "down-tunnel"
        end

        if surface.can_place_entity{name = tunnelEntityName, position = tunnel.position, force = "player"} then
            surface.create_entity{name = tunnelEntityName, position = tunnel.position, force = "player"}
        else 
            return false
        end
    end

    return true
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
            return getUndergroundSurfaceNameForLayer(surfaceName, getUndergroundSurfaceNameLayerNumber(surface) - 1)
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
        return getUndergroundSurfaceNameForLayer(surfaceName, getUndergroundSurfaceNameLayerNumber(surface) + 1)
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
        table.insert(tunnelCaveDescriptorList, getTunnelCaveDescriptor(tunnel.position))
    end

    for i, tunnel in ipairs(Surface.find_all_entities({name = "up-tunnel", surface = surfacename, area = tunnelSearchArea})) do
        local tunnelCaveDescriptor = getTunnelCaveDescriptor(tunnel.position)
        tunnelCaveDescriptor.isDownTunnel = false
        table.insert(tunnelCaveDescriptorList, getTunnelCaveDescriptor(tunnel.position))
    end

    return tunnelCaveDescriptorList
end

function getTunnelCaveDescriptor(pos)
    local tunnelCaveDescriptor = {}
    tunnelCaveDescriptor.tunnelPos = pos
    tunnelCaveDescriptor.isDownTunnel = nil
    tunnelCaveDescriptor.innerCaveArea = Area.expand(Area.construct(pos.x - 0.5, pos.y - 0.5, pos.x - 0.5, pos.y - 0.5), underexp.tunnelCaveSize)
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

    local tunnelCaveDescriptorList = getAboveAndBelowTunnelCaveDescriptorOverlappingArea(event.surface, event.area)

    for key, tunnelCaveDescriptor in ipairs(tunnelCaveDescriptorList) do
        game.print(Position.tostring(tunnelCaveDescriptor.innerCaveArea["left_top"]))
        game.print(Position.tostring(tunnelCaveDescriptor.innerCaveArea["right_bottom"]))
        game.print(Position.tostring(tunnelCaveDescriptor.outerCaveArea["left_top"]))
        game.print(Position.tostring(tunnelCaveDescriptor.outerCaveArea["right_bottom"]))
    end

    -- fill the chuck tiles
    local tiles = {}
    for x=event.area.left_top.x, event.area.right_bottom.x do
        for y=event.area.left_top.y, event.area.right_bottom.y do
            local pos = {x, y}

            -- si on doit metre un rock tile
            if table.any(tunnelCaveDescriptorList, function (v, k, pos) return isTunnelCaveDescriptorRockTile(v, pos) end, pos) then
                table.insert(tiles, {name="underground-rock", position=pos})
            else
                table.insert(tiles, {name="out-of-map", position=pos})
            end
        end
    end
    event.surface.set_tiles(tiles)

    -- fill the entity
    for x=event.area.left_top.x, event.area.right_bottom.x do
        for y=event.area.left_top.y, event.area.right_bottom.y do
            local pos = {x, y}
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
            if isRockBorder and not isRockTileAlone then
                game.print("rock: " .. Position.tostring(pos))
                event.surface.create_entity{name = "border-rock", position = pos, force = "neutral"}
            end
        end
    end

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