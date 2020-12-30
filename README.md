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
