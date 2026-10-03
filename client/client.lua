local appliedVehicles = {}
local processingVehicles = {}

local RETRY_COUNT = 8
local RETRY_DELAY = 500
local FALLBACK_SCAN_INTERVAL = 10000
local CLEANUP_INTERVAL = 60000


local function getModelName(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end

    local model = GetEntityModel(vehicle)

    if not model or model == 0 then
        return nil
    end

    local name = GetDisplayNameFromVehicleModel(model)

    if not name or name == 'CARNOTFOUND' then
        return nil
    end

    return name:lower()
end

local function getNetworkId(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end

    if not NetworkGetEntityIsNetworked(vehicle) then
        return nil
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    if not netId or netId == 0 then
        return nil
    end

    return netId
end

local function isVehicleReady(vehicle)
    return vehicle ~= 0
        and DoesEntityExist(vehicle)
        and GetEntityType(vehicle) == 2
end


local function applyEngineSound(vehicle)
    if not isVehicleReady(vehicle) then
        return false
    end

    local netId = getNetworkId(vehicle)

    if not netId then
        return false
    end

    if appliedVehicles[netId] then
        return true
    end

    local modelName = getModelName(vehicle)

    if not modelName then
        return false
    end

    local audio = Config.EngineSounds[modelName]

    if not audio then
        if Config.Debug then
            print(('[Project07_VehicleSounds] No mapping: %s')
                :format(modelName))
        end

        appliedVehicles[netId] = true

        return false
    end


    local state = Entity(vehicle).state
    local syncedSound = state.engineSound

    -- Mark BEFORE applying
    appliedVehicles[netId] = true

    if syncedSound then
        ForceVehicleEngineAudio(vehicle, syncedSound)

        if Config.Debug then
            print(('[Project07_VehicleSounds] Synced: %s -> %s')
                :format(modelName, syncedSound))
        end

        return true
    end

    state:set('engineSound', audio, true)

    ForceVehicleEngineAudio(vehicle, audio)

    if Config.Debug then
        print(('[Project07_VehicleSounds] Applied: %s -> %s')
            :format(modelName, audio))
    end

    return true
end

local function tryApplyVehicle(vehicle)
    if vehicle == 0 then
        return
    end

    if not DoesEntityExist(vehicle) then
        return
    end

    CreateThread(function()
        local netId

        for _ = 1, RETRY_COUNT do
            if not DoesEntityExist(vehicle) then
                return
            end

            netId = getNetworkId(vehicle)

            if netId then

                if appliedVehicles[netId] then
                    return
                end

                if applyEngineSound(vehicle) then
                    processingVehicles[netId] = nil
                    return
                end
            end

            Wait(RETRY_DELAY)
        end

        if netId then
            processingVehicles[netId] = nil
        end

        if Config.Debug then
            print('[Project07_VehicleSounds] Vehicle not ready')
        end
    end)
end

AddEventHandler('entityCreated', function(entity)
    if entity == 0 then
        return
    end

    if not DoesEntityExist(entity) then
        return
    end

    if GetEntityType(entity) ~= 2 then
        return
    end

    SetTimeout(100, function()
        if not DoesEntityExist(entity) then
            return
        end

        local netId = getNetworkId(entity)

        if not netId then
            tryApplyVehicle(entity)
            return
        end

        if appliedVehicles[netId] then
            return
        end

        if processingVehicles[netId] then
            return
        end

        processingVehicles[netId] = true

        tryApplyVehicle(entity)

        SetTimeout(5000, function()
            processingVehicles[netId] = nil
        end)
    end)
end)

CreateThread(function()
    Wait(2000)

    local vehicles = GetGamePool('CVehicle')

    for i = 1, #vehicles do
        local vehicle = vehicles[i]

        if DoesEntityExist(vehicle) then
            local netId = getNetworkId(vehicle)

            if netId
                and not appliedVehicles[netId]
                and not processingVehicles[netId] then

                processingVehicles[netId] = true

                tryApplyVehicle(vehicle)

                SetTimeout(5000, function()
                    processingVehicles[netId] = nil
                end)
            end
        end
    end
end)

AddStateBagChangeHandler(
    'engineSound',
    nil,
    function(bagName, _, value)
        if not value then
            return
        end

        local netId = tonumber(
            bagName:match('^entity:(%d+)$')
        )

        if not netId then
            return
        end

        if appliedVehicles[netId] then
            return
        end

        CreateThread(function()
            local vehicle = 0

            for _ = 1, 8 do
                vehicle = NetworkGetEntityFromNetworkId(netId)

                if vehicle ~= 0
                    and DoesEntityExist(vehicle) then
                    break
                end

                Wait(250)
            end

            if vehicle == 0 then
                return
            end

            if not DoesEntityExist(vehicle) then
                return
            end

            if GetEntityType(vehicle) ~= 2 then
                return
            end

            -- Another handler may have applied it
            if appliedVehicles[netId] then
                return
            end

            appliedVehicles[netId] = true

            ForceVehicleEngineAudio(vehicle, value)

            if Config.Debug then
                print(('[Project07_VehicleSounds] State synced: %s')
                    :format(value))
            end
        end)
    end
)

CreateThread(function()
    while true do
        Wait(FALLBACK_SCAN_INTERVAL)

        local vehicles = GetGamePool('CVehicle')

        for i = 1, #vehicles do
            local vehicle = vehicles[i]

            if DoesEntityExist(vehicle) then
                local netId = getNetworkId(vehicle)

                if netId
                    and not appliedVehicles[netId]
                    and not processingVehicles[netId] then

                    processingVehicles[netId] = true

                    tryApplyVehicle(vehicle)

                    SetTimeout(5000, function()
                        processingVehicles[netId] = nil
                    end)
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(CLEANUP_INTERVAL)

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
