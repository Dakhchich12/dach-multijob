Config = {}


Config.OpenCommand = 'multijob'
Config.OpenKey = 'j' -- set to false to disable keybind

--- Max jobs stored per character (0 = unlimited)
Config.MaxJobs = 8

--- Jobs are checked against QBCore.Shared.Jobs (qb-core/shared/jobs.lua).
--- Removes invalid job names from the list and clamps grades to valid keys in that file.
Config.ValidateAgainstSharedJobs = true

--- If true, on login every job defined in qb-core/shared/jobs.lua is added at grade 0 (players can switch to any).
--- WARNING: sandbox / dev only — set false for normal RP. Use Config.SharedJobsSkip to exclude jobs (e.g. unemployed).
Config.AutoAddAllSharedJobsOnLogin = false

--- Ignored when AutoAddAllSharedJobsOnLogin is true (lowercase names)
Config.SharedJobsSkip = {
    'unemployed',
}

--- Require being on duty for certain jobs (optional; off by default)
Config.RequireOnDuty = false

--- Show On duty / Off duty toggle (uses QBCore server event QBCore:ToggleDuty)
Config.EnableDutyToggle = true

--- Native GTA sound when switching job (plays on client after success)
Config.NativeConfirmSound = 'SELECT'
Config.NativeConfirmSoundSet = 'HUD_FRONTEND_DEFAULT_SOUNDSET'

--- Performance: CSS backdrop-filter on the menu can lower FPS in some setups.
--- true = no blur (heavier solid panel, usually better FPS). false = glass blur.
Config.DisableNuiBackdropBlur = true

--- UI 
Config.Locale = {
    title = 'LEBERTA MULTI JOB',
    subtitle = 'Select active job',
    current = 'Active',
    empty = 'No extra jobs — ask staff to add one.',
    switching = 'Switching…',
    close_hint = 'ESC to close',
    duty_go_on = 'on duty',
    duty_go_off = 'off duty',
}

--- Admin ACE (optional; commands use QBCore admin permission by default)
--- Example: add_ace group.admin dach-multijob.admin allow
Config.AdminAce = 'dach-multijob.admin'
