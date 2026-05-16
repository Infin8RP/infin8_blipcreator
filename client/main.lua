local BlipHandles = {}

local function ShowNotification(message)
    if GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        if QBCore and QBCore.Functions then
            QBCore.Functions.Notify(message, 'primary', 4000)
            return
        end
    end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

local function CreatePersonalBlip(id, coords, name, sprite, color, scale)
    if BlipHandles[id] then
        RemoveBlip(BlipHandles[id])
    end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, math.max(0.0, math.min(1.0, scale)))
    SetBlipAsShortRange(blip, false)
    SetBlipDisplay(blip, 6)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip)

    BlipHandles[id] = blip
    return blip
end

local function DeletePersonalBlip(id)
    if BlipHandles[id] then
        RemoveBlip(BlipHandles[id])
        BlipHandles[id] = nil
        return true
    end
    return false
end

local function LoadBlips(blips)
    for id, data in pairs(blips) do
        CreatePersonalBlip(id, data.coords, data.name, data.sprite, data.color, data.scale)
    end
end

local function CleanupBlips()
    for _, handle in pairs(BlipHandles) do
        RemoveBlip(handle)
    end
    BlipHandles = {}
end

RegisterNetEvent('personalblips:client:loadBlips', LoadBlips)

RegisterNetEvent('personalblips:client:blipCreated', function(id, coords, name, sprite, color, scale)
    CreatePersonalBlip(id, coords, name, sprite, color, scale)
end)

RegisterNetEvent('personalblips:client:blipDeleted', function(id)
    DeletePersonalBlip(id)
end)

RegisterNetEvent('personalblips:client:blipUpdated', function(id, sprite, color, scale)
    if BlipHandles[id] then
        SetBlipSprite(BlipHandles[id], sprite)
        SetBlipColour(BlipHandles[id], color)
        SetBlipScale(BlipHandles[id], math.max(0.0, math.min(1.0, scale)))
    end
end)

RegisterNetEvent('personalblips:client:receiveSharedBlip', function(id, coords, name, sprite, color, scale)
    CreatePersonalBlip(id, coords, name, sprite, color, scale)
    ShowNotification('You received a shared blip: ' .. name)
end)

RegisterNetEvent('personalblips:client:shareResult', function(success, reason)
    if success then
        ShowNotification('Blip shared successfully')
    elseif reason == 'no_player' or reason == 'out_of_range' then
        ShowNotification('No one nearby')
    elseif reason == 'target_full' then
        ShowNotification('Target player has too many blips')
    end
end)

RegisterNetEvent('personalblips:client:receiveBlipsForNUI', function(blips)
    NUI.UpdateBlips(blips)
end)

RegisterCommand('blips', function()
    NUI.Open({})
    TriggerServerEvent('personalblips:server:requestBlips')
end, false)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(1000)
        TriggerServerEvent('personalblips:server:init')
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('personalblips:server:init')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupBlips()
    end
end)
