local QBCore = exports['qb-core']:GetCoreObject()
local open = false

local function sendOpenPayload(data, silent)
    if not data or not data.jobs then return end
    SendNUIMessage({
        action = silent and 'refresh' or 'open',
        jobs = data.jobs,
        onDuty = data.onDuty,
        dutyToggle = data.dutyToggle,
        locale = Config.Locale,
        disableBackdropBlur = Config.DisableNuiBackdropBlur,
    })
end

local function closeMenu()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openMenu()
    if open then return end
    QBCore.Functions.TriggerCallback('dach-multijob:server:getJobs', function(data)
        if not data or not data.jobs then
            QBCore.Functions.Notify('Could not load jobs.', 'error')
            return
        end
        open = true
        SetNuiFocus(true, true)
        sendOpenPayload(data, false)
    end)
end

RegisterCommand(Config.OpenCommand, function()
    openMenu()
end, false)

if Config.OpenKey then
    RegisterKeyMapping(Config.OpenCommand, 'Open Multi Job Menu', 'keyboard', Config.OpenKey)
end

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb('ok')
end)

RegisterNUICallback('selectJob', function(data, cb)
    local name = data and data.name
    if type(name) == 'string' and name ~= '' then
        TriggerServerEvent('dach-multijob:server:switchJob', name)
    end
    closeMenu()
    cb('ok')
end)

--- Uses QBCore built-in duty toggle (qb-core/server/events.lua)
RegisterNUICallback('toggleDuty', function(_, cb)
    TriggerServerEvent('QBCore:ToggleDuty')
    cb('ok')
end)

RegisterNetEvent('dach-multijob:client:switchFx', function()
    if Config.NativeConfirmSound and Config.NativeConfirmSoundSet then
        PlaySoundFrontend(-1, Config.NativeConfirmSound, Config.NativeConfirmSoundSet, true)
    end
end)

--- Real job changed (boss menu, admin, other scripts): refresh list if menu is open (no extra CPU when closed)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    if not open then return end
    QBCore.Functions.TriggerCallback('dach-multijob:server:getJobs', function(data)
        if not data then return end
        sendOpenPayload(data, true)
    end)
end)
