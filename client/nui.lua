NUI = {}
local isOpen = false

function NUI.SendMessage(action, data)
    SendNuiMessage(json.encode({ action = action, data = data or {} }))
end

function NUI.SetVisibility(visible)
    NUI.SendMessage('setVisible', { visible = visible })
end

function NUI.SetFocus(hasFocus, hasCursor)
    SetNuiFocus(hasFocus, hasCursor ~= false and hasFocus)
end

function NUI.Open(data)
    if isOpen then return end
    isOpen = true
    NUI.SetFocus(true, true)
    local configData = {
        blips = data.blips,
        sprites = BlipConfig.Sprites,
        colors = BlipConfig.Colors
    }
    NUI.SendMessage('open', configData)
end

function NUI.Close()
    if not isOpen then return end
    isOpen = false
    NUI.SetFocus(false, false)
    NUI.SendMessage('close')
end

function NUI.IsOpen()
    return isOpen
end

function NUI.UpdateBlips(blips)
    NUI.SendMessage('blipsUpdated', { blips = blips })
end

RegisterNuiCallback('close', function(_, cb)
    NUI.Close()
    cb({ success = true })
end)

RegisterNuiCallback('getBlips', function(_, cb)
    TriggerServerEvent('personalblips:server:requestBlips')
    cb({ success = true })
end)

RegisterNuiCallback('createBlip', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('personalblips:server:createBlip', {
        coords = { x = coords.x, y = coords.y, z = coords.z },
        name = data.name,
        sprite = tonumber(data.sprite) or Config.Blips.DefaultSprite,
        color = data.color,
        scale = data.scale
    })
    cb({ success = true })
end)

RegisterNuiCallback('editBlip', function(data, cb)
    TriggerServerEvent('personalblips:server:editBlip', data.blipId, data.sprite, data.color, data.scale)
    cb({ success = true })
end)

RegisterNuiCallback('deleteBlip', function(data, cb)
    TriggerServerEvent('personalblips:server:deleteBlip', data.blipId)
    cb({ success = true })
end)

RegisterNuiCallback('shareBlip', function(data, cb)
    TriggerServerEvent('personalblips:server:shareBlip', data.blipId)
    cb({ success = true })
end)
