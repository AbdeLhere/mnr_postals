local path = lib.load("config.config").path
local postals = lib.load(path)

for code, coords in pairs(postals) do
    lib.grid.addEntry({
        coords = coords,
        radius = 300,
        postal = code,
    })
end
local isPostalFinderActive = false
local function isPostal(entry)
    return entry.postal ~= nil
end

local function getNearestPostal(coords)
    if not coords then
        coords = GetEntityCoords(cache.ped)
    end

    local point = vec2(coords.x, coords.y)

    local entries = lib.grid.getNearbyEntries(point, isPostal)

    local nearest, minDist = 0, math.huge

    for _, entry in ipairs(entries) do
        local dist = #(point - vec2(entry.coords.x, entry.coords.y))
        if dist < minDist then
            minDist = dist
            nearest = entry.postal
        end
    end

    return nearest
end

local function setWaypoint(code)
    local postal = postals[code]
    if not postal then
        return false
    end
    SetNewWaypoint(postal.x, postal.y)
    return true
end

local function getPostalCoords(code)
    return postals[code]
end

local function isValidPostal(code)
    return postals[code] ~= nil
end

local function getAllPostals()
    return postals
end

local function startPostalFinder()
    if isPostalFinderActive then
        return false
    end
    TriggerEvent("mnr_postals:client:StartPostalFinder")
    return true
end

local function stopPostalFinder()
    if not isPostalFinderActive then
        return false
    end
    isPostalFinderActive = false
    return true
end

local function getPostalFinderStatus()
    return isPostalFinderActive
end

RegisterNetEvent("mnr_postals:client:SetWaypoint", function(code)
    local postal = postals[code]
    if not postal then
        lib.notify({ description = locale("not-found"):format(code), position = "top", type = "error" })
        return
    end

    SetNewWaypoint(postal.x, postal.y)
    lib.notify({ description = locale("set-success"):format(code), position = "top", type = "success" })
end)

local function closePauseMenu()
    SetPauseMenuActive(false)

    if IsPauseMenuActive() then
        SetPauseMenuActive(false)
    end
end

RegisterNetEvent("mnr_postals:client:StartPostalFinder", function()
    if isPostalFinderActive then
        lib.notify({
            description = locale("finder-already-active"),
            position = "top",
            type = "error"
        })
        return
    end

    isPostalFinderActive = true

    SetWaypointOff()

    CreateThread(function()
        while isPostalFinderActive do
            Wait(500)

            if IsWaypointActive() then
                local waypointCoords = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))

                if waypointCoords then
                    local postal = getNearestPostal(waypointCoords)

                    if postal and postal ~= 0 then
                        lib.notify({
                            description = locale("postal-at-location"):format(postal),
                            position = "top",
                            type = "success"
                        })
                        Wait(100)
                        closePauseMenu()
                    else
                        lib.notify({
                            description = locale("no-postal-at-location"),
                            position = "top",
                            type = "error"
                        })
                    end

                    isPostalFinderActive = false
                    break
                end
            end
        end
    end)

    CreateThread(function()
        Wait(30000)
        if isPostalFinderActive then
            isPostalFinderActive = false
            lib.notify({
                description = locale("finder-timeout"),
                position = "top",
                type = "inform"
            })
        end
    end)
end)

RegisterNetEvent("mnr_postals:client:GetNearestPostal", function()
    local nearestPostal = getNearestPostal()
    if nearestPostal and nearestPostal ~= 0 then
        lib.notify({
            description = locale("nearest-postal"):format(nearestPostal),
            position = "top",
            type = "inform"
        })
    else
        lib.notify({
            description = locale("no-postal-found"),
            position = "top",
            type = "error"
        })
    end
end)

exports("getNearestPostal", getNearestPostal)
exports("setWaypoint", setWaypoint)
exports("getPostalCoords", getPostalCoords)
exports("isValidPostal", isValidPostal)
exports("getAllPostals", getAllPostals)
exports("startPostalFinder", startPostalFinder)
exports("stopPostalFinder", stopPostalFinder)
exports("getPostalFinderStatus", getPostalFinderStatus)
