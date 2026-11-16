# Changelog

## [v1.1.0] - 2026-11-16

Previous tag: `v1.0.0`

## Changes

- `b1a03b7` feat(system_monitor): read drive temperatures from sysfs hwmon
- `0886a1e` style(system_monitor): strip trailing whitespace
- `526d6ce` feat(system_monitor): fall back to smartctl for nvme temperature on old kernels
- `f884049` feat(system_monitor): add setup script for the nvme smartctl fallback
- `ed1184c` refactor(aristos_magic_bash): move the fallback setup to the magic bash and point to it when smartctl not found

## Comparison

- Repository: `ikh-innovation/system_monitor`
- Commits: 6
- Files changed: 4
- Compare: https://github.com/ikh-innovation/system_monitor/compare/v1.0.0...release/v1.1.0

