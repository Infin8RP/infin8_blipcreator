local Accounts = {}
local PlayerBlips = {}
local NextAccountId = 1000
local NextBlipId = 1

local function GetPlayerNameSafe(src)
    local name = GetPlayerName(src)
    return name or 'Unknown'
end

local function SendDiscordLog(title, description, color)
    if not WebhookURL or WebhookURL == '' then return end

    local embed = {
        {
            title = title,
            description = description,
            color = color,
            footer = { text = 'Personal Blip System' },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }
    }

    local payload = json.encode({ username = 'Blip Logger', embeds = embed })

    PerformHttpRequest(WebhookURL, function(err, text, headers)
        if err ~= 200 and err ~= 204 then
            print('[personalblips] Webhook error: ' .. tostring(err) .. ' - ' .. tostring(text))
        end
    end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end

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

    if not data.coords or not data.coords.x or not data.coords.y or not data.coords.z then return end

    local blipId = NextBlipId
    NextBlipId = NextBlipId + 1

    local accKey = tostring(accountId)
    local blipKey = tostring(blipId)

    local sanitizedCoords = {
        x = tonumber(data.coords.x) or 0,
        y = tonumber(data.coords.y) or 0,
        z = tonumber(data.coords.z) or 0
    }
    local sanitizedName = string.sub(tostring(data.name or 'Blip'), 1, 32)
    local sanitizedSprite = math.max(1, math.min(826, tonumber(data.sprite) or Config.Blips.DefaultSprite))
    local sanitizedColor = math.max(0, math.min(85, tonumber(data.color) or 0))
    local sanitizedScale = math.max(0.0, math.min(1.0, tonumber(data.scale) or 0.8))

    if not PlayerBlips[accKey] then
        PlayerBlips[accKey] = {}
    end

    PlayerBlips[accKey][blipKey] = {
        coords = sanitizedCoords,
        name = sanitizedName,
        sprite = sanitizedSprite,
        color = sanitizedColor,
        scale = sanitizedScale
    }

    SaveStorage()
    TriggerClientEvent('personalblips:client:blipCreated', playerSrc, blipId, sanitizedCoords, sanitizedName, sanitizedSprite, sanitizedColor, sanitizedScale)
    SendDiscordLog('Blip Created', string.format('**Player:** %s (ID: %d)\n**Blip:** %s\n**Sprite:** %d | **Color:** %d | **Scale:** %.1f', GetPlayerNameSafe(playerSrc), playerSrc, sanitizedName, sanitizedSprite, sanitizedColor, sanitizedScale), 3066993)
end)

RegisterNetEvent('personalblips:server:deleteBlip', function(blipId)
    local playerSrc = source
    local accountId = GetAccountId(playerSrc)
    if not accountId then return end

    local accKey = tostring(accountId)
    local blipKey = tostring(blipId)

    if PlayerBlips[accKey] and PlayerBlips[accKey][blipKey] then
        local blipName = PlayerBlips[accKey][blipKey].name
        PlayerBlips[accKey][blipKey] = nil
        SaveStorage()
        TriggerClientEvent('personalblips:client:blipDeleted', playerSrc, blipId)
        SendDiscordLog('Blip Deleted', string.format('**Player:** %s (ID: %d)\n**Blip:** %s (ID: %s)', GetPlayerNameSafe(playerSrc), playerSrc, blipName, blipKey), 15158332)
    end
end)

RegisterNetEvent('personalblips:server:editBlip', function(blipId, newSprite, newColor, newScale)
    local playerSrc = source
    local accountId = GetAccountId(playerSrc)
    if not accountId then return end

    local accKey = tostring(accountId)
    local blipKey = tostring(blipId)

    if PlayerBlips[accKey] and PlayerBlips[accKey][blipKey] then
        local blipName = PlayerBlips[accKey][blipKey].name
        local sanitizedSprite = math.max(1, math.min(826, tonumber(newSprite) or Config.Blips.DefaultSprite))
        local sanitizedColor = math.max(0, math.min(85, tonumber(newColor) or 0))
        local sanitizedScale = math.max(0.0, math.min(1.0, tonumber(newScale) or 0.8))
        PlayerBlips[accKey][blipKey].sprite = sanitizedSprite
        PlayerBlips[accKey][blipKey].color = sanitizedColor
        PlayerBlips[accKey][blipKey].scale = sanitizedScale
        SaveStorage()
        TriggerClientEvent('personalblips:client:blipUpdated', playerSrc, blipId, sanitizedSprite, sanitizedColor, sanitizedScale)
        SendDiscordLog('Blip Edited', string.format('**Player:** %s (ID: %d)\n**Blip:** %s\n**New Sprite:** %d | **New Color:** %d | **New Scale:** %.1f', GetPlayerNameSafe(playerSrc), playerSrc, blipName, sanitizedSprite, sanitizedColor, sanitizedScale), 15844367)
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
    SendDiscordLog('Blip Shared', string.format('**From:** %s (ID: %d)\n**To:** %s (ID: %d)\n**Blip:** %s', GetPlayerNameSafe(src), src, GetPlayerNameSafe(targetSrc), targetSrc, blipData.name), 3447003)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        LoadStorage()
    end
end)
