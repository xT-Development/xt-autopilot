local config = require 'config'
local autoPilotActive = false
local currentDriveStyle = 786603
local autoPilotSpeed = 0
local autoPilotText = false
local speedType = config.useMPH and 'MPH' or 'KPH'
local GetEntityCoords = GetEntityCoords

-- Disables Autopilot --
local function disableAutoPilot()
    autoPilotActive = false
    currentDriveStyle = 786603
    autoPilotSpeed = 0

    ClearPedTasks(cache.ped)
    lib.notify({ title = 'Autopilot Disabled', type = 'error' })
    lib.hideTextUI()
end

-- Change Drive Style --
local function changeDriveStyleInput()
    local newStyle = lib.inputDialog('Drive Style', {
        { type = 'select', label = 'Select Drivestyle', options = config.driveStyles, required = true },
    }) if not newStyle then return end

    currentDriveStyle = newStyle[1]

    lib.notify({ title = ('Drivestyle Changed: %s'):format(drivestyleToString(currentDriveStyle)), type = 'success' })

    setAutoPilotValues(autoPilotSpeed, newStyle[1])
end

-- Change Speed --
local function changeSpeedInput()
    local speedInput = lib.inputDialog('Autopilot Speed', {
        { type = 'number', label = ('Set Max Speed (%s)'):format(speedType), required = true },
    }) if not speedInput then return end

    autoPilotSpeed = speedInput[1]

    lib.notify({ title = ('Speed Changed: %s %s'):format(autoPilotSpeed, speedType), type = 'success' })

    setAutoPilotValues(autoPilotSpeed, currentDriveStyle)
end

-- Autopilot Menu --
local function autoPilotMenu()
    lib.registerContext({
        id = 'autopilot_menu',
        title = 'Autopilot Settings',
        options = {
            {
                title = 'Change Max Speed',
                description = ('**Speed:** %s %s'):format(autoPilotSpeed, speedType),
                icon = 'fas fa-car',
                onSelect = function()
                    changeSpeedInput()
                end
            },
            {
                title = 'Change Drive Style',
                description = ('**Style:** %s'):format(drivestyleToString(currentDriveStyle)),
                icon = 'fas fa-car',
                onSelect = function()
                    changeDriveStyleInput()
                end
            },
            {
                title = 'Disable Autopilot',
                icon = 'fas fa-ban',
                onSelect = function()
                    disableAutoPilot()
                end
            }
        }
    })
    lib.showContext('autopilot_menu')
end

-- Distance Check from Waypoint --
local function startDistanceLoop()
    if not autoPilotActive then return end

    while autoPilotActive do
        local wpCoords = getWaypointCoords()
        local vCoords = GetEntityCoords(cache.vehicle)
        local dist = #(wpCoords - vCoords)

        if dist <= config.stopAutoPilotDistance then
            lib.notify({ title = 'Arrived at Destination', type = 'success' })
            disableAutoPilot()
        end

        Wait(1000)
    end
end

-- Autopilot Toggle --
local function toggleAutoPilot()
    if not autoPilotActive then
        local speedInput = lib.inputDialog('Autopilot Speed', {
            { type = 'number', label = ('Set Max Speed (%s)'):format(speedType), required = true },
            { type = 'select', label = 'Select Drivestyle', options = config.driveStyles, required = true },
        }) if not speedInput then return end

        autoPilotSpeed = speedInput[1]
        currentDriveStyle = speedInput[2]

        lib.notify({ title = 'Autopilot Enabled', type = 'success' })

        lib.showTextUI(('**Autopilot:** %s  \n**Speed:** %s %s'):format(drivestyleToString(currentDriveStyle), autoPilotSpeed, speedType), {
            position = "left-center",
            icon = 'fas fa-car-side',
        })

        setAutoPilotValues(autoPilotSpeed, currentDriveStyle)

        autoPilotActive = true

        startDistanceLoop()
    else
        autoPilotMenu()
    end
end

-- Autopilot Key --
local autopilotKey = lib.addKeybind({
    name = 'autopilot',
    description = ('Autopilot Controls'):format(config.keybind),
    defaultKey = config.keybind,
    onReleased = function(self)
        if not cache.vehicle then return end

        if GetPedInVehicleSeat(cache.vehicle, -1) == cache.ped then
            if IsWaypointActive() then
                toggleAutoPilot()
            else
                lib.notify({ title = 'No waypoint active!', type = 'error' })
            end
        else
            lib.notify({ title = 'You are not driving!', type = 'error' })
        end
    end
})

lib.onCache('vehicle', function(newVeh)
    if not autoPilotActive then return end
    if cache.vehicle and not newVeh then
        disableAutoPilot()
    end
end)

lib.onCache('seat', function(newSeat)
    if not autoPilotActive then return end
    if cache.vehicle and cache.seat == -1 and newSeat ~= -1 then
        disableAutoPilot()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if autoPilotActive then
        disableAutoPilot()
    end
end)