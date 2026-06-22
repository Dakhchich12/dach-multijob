local QBCore = exports['qb-core']:GetCoreObject()
local function clampGradeToShared(jobName, grade)
    jobName = jobName:lower()
    local sh = QBCore.Shared.Jobs[jobName]
    if not sh or not sh.grades then return 0 end
    local g = tonumber(grade) or 0
    if sh.grades[tostring(g)] then return g end
    local maxG = 0
    for k, _ in pairs(sh.grades) do
        local n = tonumber(k)
        if n and n > maxG then maxG = n end
    end
    if g > maxG then return maxG end
    if g < 0 then g = 0 end
    for test = g, 0, -1 do
        if sh.grades[tostring(test)] then return test end
    end
    return 0
end

local function sanitizeMultijobs(Player)
    if not Config.ValidateAgainstSharedJobs then return false end
    local list = Player.PlayerData.metadata.multijobs
    if type(list) ~= 'table' then return false end

    local newList = {}
    local changed = false
    for _, entry in ipairs(list) do
        local jname = entry.name and entry.name:lower()
        if jname and QBCore.Shared.Jobs[jname] then
            local g = clampGradeToShared(jname, entry.grade)
            newList[#newList + 1] = { name = jname, grade = g }
            if g ~= tonumber(entry.grade) then changed = true end
        else
            changed = true
        end
    end

    if #newList == 0 then
        local j = Player.PlayerData.job
        local jn = j.name:lower()
        newList[1] = { name = jn, grade = clampGradeToShared(jn, j.grade.level) }
        changed = true
    end

    if changed then
        Player.Functions.SetMetaData('multijobs', newList)
        Player.Functions.Save()
    end
    return changed
end

local function ensureMultijobs(Player)
    local m = Player.PlayerData.metadata.multijobs
    if type(m) ~= 'table' then m = {} end
    if #m == 0 then
        local j = Player.PlayerData.job
        local jn = j.name:lower()
        m = {
            { name = jn, grade = clampGradeToShared(jn, j.grade.level) },
        }
        Player.Functions.SetMetaData('multijobs', m)
        Player.Functions.Save()
    end
    return Player.PlayerData.metadata.multijobs
end

local function mergeAllSharedJobsIfEnabled(Player)
    if not Config.AutoAddAllSharedJobsOnLogin then return end

    local skip = {}
    for _, s in ipairs(Config.SharedJobsSkip or {}) do
        skip[(tostring(s)):lower()] = true
    end

    ensureMultijobs(Player)
    local list = Player.PlayerData.metadata.multijobs
    if type(list) ~= 'table' then return end

    local seen = {}
    for _, e in ipairs(list) do
        seen[e.name:lower()] = true
    end

    local changed = false
    for jobName, _ in pairs(QBCore.Shared.Jobs) do
        local jn = (type(jobName) == 'string' and jobName or tostring(jobName)):lower()
        if not skip[jn] and not seen[jn] then
            if Config.MaxJobs > 0 and #list >= Config.MaxJobs then break end
            local g = clampGradeToShared(jn, 0)
            list[#list + 1] = { name = jn, grade = g }
            seen[jn] = true
            changed = true
        end
    end

    if changed then
        Player.Functions.SetMetaData('multijobs', list)
        Player.Functions.Save()
    end
end

local function findJobIndex(list, name)
    name = name:lower()
    for i, entry in ipairs(list) do
        if entry.name:lower() == name then
            return i
        end
    end
    return nil
end

local function syncMultijobsWithJob(Player)
    local job = Player.PlayerData.job
    if not job or not job.name then return end

    local jname = job.name:lower()
    local grade = tonumber(job.grade and job.grade.level) or 0

    local list = ensureMultijobs(Player)
    if type(list) ~= 'table' then return end

    local idx = findJobIndex(list, jname)
    local changed = false

    if not QBCore.Shared.Jobs[jname] then return end
    grade = clampGradeToShared(jname, grade)

    if idx then
        if tonumber(list[idx].grade) ~= grade then
            list[idx].grade = grade
            changed = true
        end
    else
        list[#list + 1] = { name = jname, grade = grade }
        changed = true
    end

    if changed then
        Player.Functions.SetMetaData('multijobs', list)
        Player.Functions.Save()
    end
end

local function jobLabel(name)
    local j = QBCore.Shared.Jobs[name:lower()]
    return j and j.label or name
end

local function buildJobList(Player)
    ensureMultijobs(Player)
    syncMultijobsWithJob(Player)
    sanitizeMultijobs(Player)
    local list = ensureMultijobs(Player)
    local active = Player.PlayerData.job.name:lower()
    local out = {}
    for _, entry in ipairs(list) do
        local jname = entry.name:lower()
        local grade = tonumber(entry.grade) or 0
        local shared = QBCore.Shared.Jobs[jname]
        local gradeLabel = 'Employee'
        if shared and shared.grades and shared.grades[tostring(grade)] then
            gradeLabel = shared.grades[tostring(grade)].name
        end
        out[#out + 1] = {
            name = jname,
            label = shared and shared.label or jname,
            grade = grade,
            gradeLabel = gradeLabel,
            active = (jname == active),
        }
    end
    return out
end

QBCore.Functions.CreateCallback('dach-multijob:server:getJobs', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(nil)
        return
    end
    cb({
        jobs = buildJobList(Player),
        onDuty = Player.PlayerData.job and Player.PlayerData.job.onduty == true,
        dutyToggle = Config.EnableDutyToggle == true,
    })
end)

RegisterNetEvent('dach-multijob:server:switchJob', function(jobName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or type(jobName) ~= 'string' then return end

    jobName = jobName:lower()
    local list = ensureMultijobs(Player)
    local idx = findJobIndex(list, jobName)
    if not idx then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have this job.', 'error')
        return
    end

    local entry = list[idx]
    local grade = clampGradeToShared(jobName, entry.grade)
    if not QBCore.Shared.Jobs[jobName] then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid job in database.', 'error')
        return
    end

    Player.Functions.SetJob(jobName, grade)
    Player.Functions.Save()
    TriggerClientEvent('dach-multijob:client:switchFx', src)
    TriggerClientEvent('QBCore:Notify', src, ('Now working as: %s'):format(jobLabel(jobName)), 'success')
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    CreateThread(function()
        Wait(1500)
        local P = QBCore.Functions.GetPlayer(Player.PlayerData.source)
        if P then
            ensureMultijobs(P)
            mergeAllSharedJobsIfEnabled(P)
            syncMultijobsWithJob(P)
            sanitizeMultijobs(P)
        end
    end)
end)


AddEventHandler('QBCore:Server:OnJobUpdate', function(source, _)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    syncMultijobsWithJob(Player)
    sanitizeMultijobs(Player)
end)


local function addJobInternal(src, jobName, grade)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false, 'offline' end
    jobName = jobName:lower()
    if not QBCore.Shared.Jobs[jobName] then return false, 'bad_job' end
    grade = clampGradeToShared(jobName, grade)

    local list = ensureMultijobs(Player)
    local idx = findJobIndex(list, jobName)
    if idx then
        list[idx].grade = grade
    else
        if Config.MaxJobs > 0 and #list >= Config.MaxJobs then
            return false, 'max'
        end
        list[#list + 1] = { name = jobName, grade = grade }
    end
    Player.Functions.SetMetaData('multijobs', list)
    Player.Functions.Save()
    return true
end

exports('AddJob', function(source, jobName, grade)
    return addJobInternal(source, jobName, grade)
end)

local function removeJobInternal(source, jobName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    jobName = jobName:lower()
    local list = ensureMultijobs(Player)
    local idx = findJobIndex(list, jobName)
    if not idx then return false end
    table.remove(list, idx)
    if #list == 0 then
        list[1] = { name = 'unemployed', grade = 0 }
    end
    Player.Functions.SetMetaData('multijobs', list)
    if Player.PlayerData.job.name:lower() == jobName then
        local first = list[1]
        Player.Functions.SetJob(first.name, first.grade)
    end
    Player.Functions.Save()
    return true
end

exports('RemoveJob', function(source, jobName)
    return removeJobInternal(source, jobName)
end)


QBCore.Commands.Add('addmultijob', 'Add a job slot to target player (Admin)', {
    { name = 'id', help = 'Player server id' },
    { name = 'job', help = 'Job name' },
    { name = 'grade', help = 'Grade number' },
}, true, function(source, args)
    local tid = tonumber(args[1])
    local job = args[2]
    local grade = tonumber(args[3]) or 0
    if not tid or not job then return end
    local ok, reason = addJobInternal(tid, job, grade)
    if ok then
        TriggerClientEvent('QBCore:Notify', source, 'Job added to multijob list.', 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, ('Failed: %s'):format(reason or 'unknown'), 'error')
    end
end, 'admin')

QBCore.Commands.Add('removemultijob', 'Remove a job from target player (Admin)', {
    { name = 'id', help = 'Player server id' },
    { name = 'job', help = 'Job name' },
}, true, function(source, args)
    local tid = tonumber(args[1])
    local job = args[2]
    if not tid or not job then return end
    if removeJobInternal(tid, job) then
        TriggerClientEvent('QBCore:Notify', source, 'Job removed.', 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'Failed.', 'error')
    end
end, 'admin')
