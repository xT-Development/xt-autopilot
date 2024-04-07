local config = require 'config'
local speedMult = config.useMPH and 2.24 or 3.6
local speedType = config.useMPH and 'MPH' or 'KPH'

local GetFirstBlipInfoId = GetFirstBlipInfoId
local GetBlipInfoIdCoord = GetBlipInfoIdCoord

-- Set Autopilot Values --
function setAutoPilotValues(speed, style)
    lib.showTextUI(('**Autopilot:** %s  \n**Speed:** %s %s'):format(drivestyleToString(style), speed, speedType), {
        position = "left-center",
        icon = 'fas fa-car-side',
    })

    local wpCoords = getWaypointCoords()
    local vehModel = GetEntityModel(cache.vehicle)
    TaskVehicleDriveToCoord(cache.ped, cache.vehicle, wpCoords.x, wpCoords.y, wpCoords.z, (speed / speedMult), 0, vehModel, style, 0, true)
end

-- Returns Drive Style String --
function drivestyleToString(style)
    local callback

    for x = 1, #config.driveStyles do
        if style == config.driveStyles[x].value then
            callback = config.driveStyles[x].label
            break
        end
    end

    return callback
end

-- Get Coords for Waypoint --
function getWaypointCoords()
    local waypoint = GetFirstBlipInfoId(8)
    local waypointCoords = GetBlipInfoIdCoord(waypoint)
    local x, y, z = waypointCoords.x, waypointCoords.y, waypointCoords.z
    return vec3(x,y,z)
end