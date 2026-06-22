# dach-multijob

Modern **multi job** menu for **QBCore**: fully **transparent** NUI (game world visible), **Web Audio** UI sounds, smooth CSS transitions.

## Install

1. Place `dach-multijob` in `resources/[qb]/` (or your resources folder).
2. In `server.cfg`:

```cfg
ensure dach-multijob
```

3. After `qb-core` and `oxmysql`.

**Remove** `ensure dach-multijob` if you used the old name.

## Usage

- **Command:** `/multijob` (see `Config.OpenCommand`)
- **Key:** see `Config.OpenKey` (set to `false` to disable)
- **Duty:** footer button **Go on duty** / **Go off duty** calls QBCore’s `QBCore:ToggleDuty` (same as other QB scripts). Disable with `Config.EnableDutyToggle = false`.

## Giving players extra jobs

Jobs are stored in player **metadata** under `multijobs` as:

```lua
{ { name = "police", grade = 2 }, { name = "mechanic", grade = 1 } }
```

On first load, the script seeds the list from the player’s **current** job.

### From another resource

```lua
exports['dach-multijob']:AddJob(source, 'police', 2)
exports['dach-multijob']:RemoveJob(source, 'police')
```

### Admin (QBCore `admin` permission)

```
/addmultijob [id] [job] [grade]
/removemultijob [id] [job]
```

## Notes

- Switching jobs uses `Player.Functions.SetJob` (same as QBCore).
- **qb-core/shared/jobs.lua:** all job names and grades are validated against **`QBCore.Shared.Jobs`** (same data as `qb-core/shared/jobs.lua`). Invalid jobs are removed; grades are **clamped** to valid grade keys in that file.
- **`Config.AutoAddAllSharedJobsOnLogin`:** set **`true`** to automatically add **every** job from `qb-core/shared/jobs.lua` at grade **0** on login (so the menu lists all jobs). Default is **`false`** (normal RP). Use **`Config.SharedJobsSkip`** to exclude jobs (e.g. `unemployed`).
- **Job sync:** the list is updated when your **real** QBCore job changes (boss menu, admin, other scripts): the current job is added if missing and the **grade** is kept in sync. Opening the menu also refreshes from the server.
- **FPS:** the client no longer runs a tight `Wait(0)` loop while the menu is open. Set `Config.DisableNuiBackdropBlur = true` (default) to disable expensive CSS `backdrop-filter` on the panel.
- UI sounds use the **Web Audio API**. A native GTA **confirm** sound plays on successful switch (configurable in `config.lua`).
