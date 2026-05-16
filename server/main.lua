local Accounts = {}
local PlayerBlips = {}
local NextAccountId = 1000
local NextBlipId = 1

local function LoadStorage()
    local file = LoadResourceFile(GetCurrentResourceName(), Config.Storage.FileName)
    if file then
        local data = json.decode(file)
        if data then
            Accounts = data.accounts or {}
            PlayerBlips = data.blips or {}
            NextAccountId = data.nextAccountId or 1000
            NextBlipId = data.nextBlipId or 1
        end
    end
end

local function SaveStorage()
    local data = {
        accounts = Accounts,
        blips = PlayerBlips,
        nextAccountId = NextAccountId,
        nextBlipId = NextBlipId
    }
    SaveResourceFile(GetCurrentResourceName(), Config.Storage.FileName, json.encode(data, { indent = true }), -1)
end

local function GetOrCreateAccountId(playerSrc)
    local identifier = GetLicenseIdentifier(playerSrc)
    if not identifier then return nil end

    if Accounts[identifier] then
        return Accounts[identifier]
    end

    local accountId = NextAccountId
    NextAccountId = NextAccountId + 1
    Accounts[identifier] = accountId
    SaveStorage()

    return accountId
end

local function GetAccountId(playerSrc)
    local identifier = GetLicenseIdentifier(playerSrc)
    if not identifier then return nil end
    return Accounts[identifier]
end

local function GetPlayerBlipCount(accountId)
    local count = 0
    if PlayerBlips[tostring(accountId)] then
        for _ in pairs(PlayerBlips[tostring(accountId)]) do
            count = count + 1
        end
    end
    return count
end

local function GetClosestPlayer(src)
    local srcCoords = GetEntityCoords(GetPlayerPed(src))
    local closestPlayer = nil
    local closestDist = nil

    local players = GetPlayers()
    for _, player in ipairs(players) do
        local targetSrc = tonumber(player)
        if targetSrc and targetSrc ~= src then
            local targetPed = GetPlayerPed(targetSrc)
            if targetPed then
                local targetCoords = GetEntityCoords(targetPed)
                local dist = #(srcCoords - targetCoords)
                if not closestDist or dist < closestDist then
                    closestDist = dist
                    closestPlayer = targetSrc
                end
            end
        end
    end

    return closestPlayer, closestDist
end

RegisterNetEvent('personalblips:server:init', function()
    local playerSrc = source
    local accountId = GetOrCreateAccountId(playerSrc)
    if not accountId then return end

    local blips = PlayerBlips[tostring(accountId)] or {}
    TriggerClientEvent('personalblips:client:loadBlips', playerSrc, blips)
end)

RegisterNetEvent('personalblips:server:requestBlips', function()
    local playerSrc = source
    local accountId = GetAccountId(playerSrc)
    if not accountId then return end

    local blips = PlayerBlips[tostring(accountId)] or {}
    TriggerClientEvent('personalblips:client:receiveBlipsForNUI', playerSrc, blips)
end)

RegisterNetEvent('personalblips:server:createBlip', function(data)
    local playerSrc = source
    local accountId = GetOrCreateAccountId(playerSrc)
    if not accountId then return end

    if GetPlayerBlipCount(accountId) >= Config.Blips.MaxPerPlayer then
        return
    end

    local blipId
    if data.blipId and data.blipId ~= '' then
        blipId = tonumber(data.blipId) or data.blipId
        if PlayerBlips[tostring(accountId)] and PlayerBlips[tostring(accountId)][tostring(blipId)] then
            blipId = NextBlipId
            NextBlipId = NextBlipId + 1
        else
            if type(blipId) == 'number' and blipId >= NextBlipId then
                NextBlipId = blipId + 1
            end
        end
    else
        blipId = NextBlipId
        NextBlipId = NextBlipId + 1
    end

    local accKey = tostring(accountId)
    local blipKey = tostring(blipId)

    if not PlayerBlips[accKey] then
        PlayerBlips[accKey] = {}
    end

    PlayerBlips[accKey][blipKey] = {
        coords = data.coords,
        name = data.name,
        sprite = data.sprite,
        color = data.color,
        scale = data.scale
    }

    SaveStorage()
    TriggerClientEvent('personalblips:client:blipCreated', playerSrc, blipId, data.coords, data.name, data.sprite, data.color, data.scale)
end)

RegisterNetEvent('personalblips:server:deleteBlip', function(blipId)
    local playerSrc = source
    local accountId = GetAccountId(playerSrc)
    if not accountId then return end

    local accKey = tostring(accountId)
    local blipKey = tostring(blipId)

    if PlayerBlips[accKey] and PlayerBlips[accKey][blipKey] then
        PlayerBlips[accKey][blipKey] = nil
        SaveStorage()
        TriggerClientEvent('personalblips:client:blipDeleted', playerSrc, blipId)
    end
end)

RegisterNetEvent('personalblips:server:editBlip', function(blipId, newSprite, newColor, newScale)
    local playerSrc = source
    local accountId = GetAccountId(playerSrc)
    if not accountId then return end

    local accKey = tostring(accountId)
    local blipKey = tostring(blipId)

    if PlayerBlips[accKey] and PlayerBlips[accKey][blipKey] then
        PlayerBlips[accKey][blipKey].sprite = newSprite
        PlayerBlips[accKey][blipKey].color = newColor
        PlayerBlips[accKey][blipKey].scale = newScale
        SaveStorage()
        TriggerClientEvent('personalblips:client:blipUpdated', playerSrc, blipId, newSprite, newColor, newScale)
    end
end)

RegisterNetEvent('personalblips:server:shareBlip', function(blipId)
    local src = source
    local accountId = GetAccountId(src)
    if not accountId then return end

    local blipKey = tostring(blipId)
    local blipData = PlayerBlips[tostring(accountId)] and PlayerBlips[tostring(accountId)][blipKey]
    if not blipData then return end

    local targetSrc, distance = GetClosestPlayer(src)
    if not targetSrc then
        TriggerClientEvent('personalblips:client:shareResult', src, false, 'no_player')
        return
    end

    if not distance or distance > Config.Blips.ShareDistance then
        TriggerClientEvent('personalblips:client:shareResult', src, false, 'out_of_range')
        return
    end

    local targetAccountId = GetOrCreateAccountId(targetSrc)
    if not targetAccountId then return end

    if GetPlayerBlipCount(targetAccountId) >= Config.Blips.MaxPerPlayer then
        TriggerClientEvent('personalblips:client:shareResult', src, false, 'target_full')
        return
    end

    local newBlipId = NextBlipId
    NextBlipId = NextBlipId + 1

    local targetAccKey = tostring(targetAccountId)
    local newBlipKey = tostring(newBlipId)

    if not PlayerBlips[targetAccKey] then
        PlayerBlips[targetAccKey] = {}
    end

    PlayerBlips[targetAccKey][newBlipKey] = {
        coords = blipData.coords,
        name = blipData.name,
        sprite = blipData.sprite,
        color = blipData.color,
        scale = blipData.scale
    }

    SaveStorage()
    TriggerClientEvent('personalblips:client:shareResult', src, true)
    TriggerClientEvent('personalblips:client:receiveSharedBlip', targetSrc, newBlipId, blipData.coords, blipData.name, blipData.sprite, blipData.color, blipData.scale)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        LoadStorage()
    end
end)
