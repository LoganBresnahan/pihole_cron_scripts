# pihole_cron_scripts

Three simple scripts written with the intent to be run by a cron job scheduler.

> **Compatibility note:** These scripts were originally written and tested against Pi-hole v5.x (circa 2021), when `gravity.db` had its original schema and the CLI exposed `pihole updatePihole` / `pihole updateGravity`. Pi-hole v6 (released February 2025) changed both the CLI surface and parts of the database layout. They have **not** been verified against v6+ — review and test on your installation before relying on them.

In my own pihole system I've added these to the `/etc/cron.daily` directory. Scripts inside this directory are handled by `anacron`. To make them executable make sure to run:

```bash
sudo chmod +x <file_name>
sudo chown root:root <file_name>
```

Anacron runs scripts in alphabetical order. For just these scripts specifically they would be run in the order of:
1. cloudflared-updater
2. pihole-adlist-adder-remover
3. pihole-gravity-updater

## Tests

`test/test-adlist-adder-remover.sh` runs `pihole-adlist-adder-remover` against a throwaway sqlite DB and a `file://` fake firebog response. Requires `sqlite3` and `curl`. Run from the repo root:

```bash
sh test/test-adlist-adder-remover.sh
```

<br/>
<br/>

Copyright 2021 Logan Bresnahan

This file is part of pihole_cron_scripts.

pihole_cron_scripts is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

pihole_cron_scripts is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with pihole_cron_scripts. If not, see <https://www.gnu.org/licenses/>.
