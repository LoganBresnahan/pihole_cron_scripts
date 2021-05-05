# pihole_cron_scripts

Three simple scripts written with the intent to be run by a cron job scheduler.

In my own pihole system I've added these to the `/etc/cron.daily` directory. Scripts inside this directory are handled by `anacron`. To make them executable make sure to run:

```bash
sudo chmod +x <file_name>
sudo chown root:root <file_name>
```

Anacron runs scripts in alphabetical order. For just these scripts specifically they would be run in the order of:
1. cloudflared-updater
2. pihole-adlist-adder-remover
3. pihole-gravity-updater

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
