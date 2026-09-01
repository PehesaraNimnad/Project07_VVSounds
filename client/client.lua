local appliedVehicles = {}
local processingVehicles = {}

local function getModelName(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    local model = GetEntityModel(vehicle)
    if not model or model == 0 then return nil end
    return GetDisplayNameFromVehicleModel(model):lower()
end

local function getNetworkId(vehicle)
    if not vehicle or vehicle == 0 then
        return nil
    end
    if not DoesEntityExist(vehicle) then
        return nil
    end
    -- IMPORTANT: Don't call NetworkGetNetworkIdFromEntity
    -- on a non-networked/local entity
    if not NetworkGetEntityIsNetworked(vehicle) then
        return nil
    end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if not netId or netId == 0 then
        return nil
    end
    return netId
end

local function applyEngineSound(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    if GetEntityType(vehicle) ~= 2 then return false end
    local netId = getNetworkId(vehicle)
    if not netId then
        return false
    end
    -- Already applied - NEVER touch audio again
    if appliedVehicles[netId] then
        return true
    end
    local modelName = getModelName(vehicle)
    if not modelName or modelName == '' then
        return false
    end
    local audio = Config.EngineSounds[modelName]
    if not audio then
        if Config.Debug then
            print(('[Project07_VehicleSounds] No mapping for: %s'):format(modelName))
        end
        return false
    end
    local stateSound = Entity(vehicle).state.engineSound
    -- Mark before applying so scanner/statebag can't duplicate it
    appliedVehicles[netId] = true
    -- If another client already synced a sound, use it
    if stateSound then
        ForceVehicleEngineAudio(vehicle, stateSound)
        if Config.Debug then
            print(('[Project07_VehicleSounds] Applied synced sound %s [%s]')
                :format(stateSound, modelName))
        end
        return true
    end
    -- No synced sound yet, set it
    Entity(vehicle).state:set('engineSound', audio, true)
    -- Apply sound ONCE
    ForceVehicleEngineAudio(vehicle, audio)
    if Config.Debug then
        print(('[Project07_VehicleSounds] Applied %s -> %s')
            :format(modelName, audio))
    end
    return true
end

local function tryApplyVehicle(vehicle)
    if not vehicle or vehicle == 0 then return end
    CreateThread(function()
        -- Retry for a few seconds because garage/PDM vehicles
        -- can take time to become networked
        for _ = 1, 20 do
            if not DoesEntityExist(vehicle) then
                return
            end
            local netId = getNetworkId(vehicle)
            if netId then
                if applyEngineSound(vehicle) then
                    return
                end
            end
            Wait(250)
        end
        if Config.Debug then
            print('[Project07_VehicleSounds] Vehicle was not ready after retry')
        end
    end)
end
-- New vehicle/entity
AddEventHandler('entityCreated', function(entity)
    if not DoesEntityExist(entity) then return end
    if GetEntityType(entity) ~= 2 then return end

    tryApplyVehicle(entity)
end)
-- Existing vehicles when resource starts
CreateThread(function()
    Wait(1500)
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        tryApplyVehicle(vehicle)
    end
end)
-- Statebag sync
AddStateBagChangeHandler('engineSound', nil, function(bagName, _, value)
    if not value then return end

    local netId = tonumber(bagName:match('^entity:(%d+)$'))
    if not netId then return end
    CreateThread(function()
        local vehicle = 0
        for _ = 1, 20 do
            vehicle = NetworkGetEntityFromNetworkId(netId)
            if vehicle ~= 0
                and DoesEntityExist(vehicle) then
                break
            end
            Wait(250)
        end
        if vehicle == 0 or not DoesEntityExist(vehicle) then
            return
        end
        if GetEntityType(vehicle) ~= 2 then return end
        if appliedVehicles[netId] then
            return
        end
        appliedVehicles[netId] = true
        -- Apply synced sound ONCE
        ForceVehicleEngineAudio(vehicle, value)

        if Config.Debug then
            print(('[Project07_VehicleSounds] Synced sound: %s')
                :format(value))
        end
    end)
end)
-- Scan for newly spawned vehicles that entityCreated might miss
-- Already applied vehicles are completely ignored
CreateThread(function()
    while true do
        Wait(2000)
        for _, vehicle in ipairs(GetGamePool('CVehicle')) do
            if DoesEntityExist(vehicle)
                and GetEntityType(vehicle) == 2 then
                local netId = getNetworkId(vehicle)
                if netId
                    and not appliedVehicles[netId]
                    and not processingVehicles[netId] then
                    processingVehicles[netId] = true
                    tryApplyVehicle(vehicle)
                    CreateThread(function()
                        Wait(5500)

                        if netId then
                            processingVehicles[netId] = nil
                        end
                    end)
                end
            end
        end
    end
end)
-- Cleanup
CreateThread(function()
    while true do
        Wait(30000)

        for netId in pairs(appliedVehicles) do
            local vehicle = NetworkGetEntityFromNetworkId(netId)

            if vehicle == 0
                or not DoesEntityExist(vehicle) then

                appliedVehicles[netId] = nil
                processingVehicles[netId] = nil
            end
        end
    end
end)