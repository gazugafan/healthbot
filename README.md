# HealthBot
Ridiculously simple server health alerts

This is an extremely lightweight, stupidly simple to extend, and easy to hack server health monitor. For when Zabbix, Cacti, NetData, OpenNMS, Icigna, etc. are WAY overkill. Use it to make sure your server isn't about to explode for some reason.

## Requirements
Should run on most Linux servers. All dependencies are probably already installed, like `curl`, `wget`, `grep`, `awk`, `cut`, `tr` etc.

## Installation
Just run `install.sh` as root. Here's a one-liner to download that file from this repository, run it, and then delete it...
```
sudo wget -q https://raw.githubusercontent.com/gazugafan/healthbot/master/install.sh && sudo bash install.sh; sudo rm -f install.sh
```

If you'd rather install manually, here's what the install script does...
* Puts `src/healthbot.sh` at `/usr/bin/healthbot` with 755 permissions
* Puts everything in `src/etc/healthbot` at `/etc/healthbot` with 755 permissions (files here can be run as bash scripts with full root permissions, so be sure to restrict write permissions)
* Creates a cronjob file at `/etc/cron.d` that runs `/usr/bin/healthbot` every hour as root

## Configuration
Default configuration files will be created at `/etc/healthbot`. Only files ending in `.enabled` are used. Everything else is disabled and will always be ignored by HealthBot. This makes it easy to toggle features on/off.

Importantly, the HealthBot configuration files are just regular bash scripts. You can put any commands you'd like in them, and they'll be run like normal if HealthBot decides to load the file. In fact, each configuration file actually contains the code to perform its own task. This keeps things organized and makes it super easy to add your own health checks and alerts.

The main configuration file is `/etc/healthbot/general.enabled`, but really the only thing in there is a little documentation and a single option for alert throttling. You might want to throttle alerts after you're done testing to make sure you don't end up spamming yourself whenever a health problem occurs.

## Health Checks
In `/etc/healthbot/checks` you'll find all of the health checks that HealthBot will perform every time it runs. Again, only ones ending with `.enabled` will be included. Anything else is disabled. The available health checks out-of-the-box are...
* **storage:** check for low disk space
* **inodes:** check for low inode availability
* **swap:** check for low swap disk space
* **memory:** check for high system memory usage
* **load:** check for high average load
* **processes:** make sure important processes are running
* **web:** make sure a web request returns as expected
* **ping:** make sure certain servers or services are responding
* **replication:** check that a MySQL replicant is running well
* **backup:** check that a recent local backup file exists
* **supervisor:** check that all supervisord processes are running
* **docker:** check that important docker containers are running

Just change the extensions on these configuration files to `.enabled` or `.disabled` to turn on the ones you want. Edit each file to tweak their configuration options. If you look below the configuration options in each file, you'll see the actual code that runs to perform the check. They're all REALLY simple. Feel free to hack at them. Or better yet, copy and paste one to start creating your own!

## Alerts
In `/etc/healthbot/alerts` you'll find all of the alerts that HealthBot will send whenever the health checks find any problems. Again, only ones ending with `.enabled` are enabled. Anything else is disabled. There are 2 included out-of-the-box...
* **stdout:** just echos out the problems to the commandline. Mostly useful for testing, or maybe for piping to something else
* **ifttt:** Sends the problems to an [IFTTT webhook](https://ifttt.com/maker_webhooks). You can use this as an IFTTT trigger and then do whatever you want with it. Like maybe send yourself an email or give yourself a call?
* **smtp:** Sends an email over secure SMTP (STARTTLS) using your credentials. Only requires openssl and base64 (usually already installed). Great way to get a text message!

## How it works
The main HealthBot script is run via an hourly cronjob (you might consider increasing the frequency after everything is configured). Everytime it runs, it...
1) Loads the enabled general configuration file(s) at `/etc/healthbot` (probably just that one `general.enabled` file).
2) Runs the enabled health checks in `/etc/healthbot/checks`
3) If any problems are found, and alert throttling isn't an issue, it runs all the enabled alerts in `/etc/healthbot/alerts`

## Testing
Just run `healthbot` to run HealthBot once and test your configuration immediately. By default, stdout alerts are enabled, which will echo out any problems back to the command-line for you to see. If you don't see anything, it's possible that all of the default health checks are passing. By default, HealthBot checks to make sure nginx, php-fpm, and mysqld are running in the processes check, and that you're not running lower than 80% capacity on storage/swap/inode space in the storage, swap, and inode checks. Tweak some of those thresholds or add some dummy processes to see health problems in action!

## Extending
It's so easy! Just copy one of the checks or alerts and use it as a base to create your own. Each one contains both it's own configuration options AND the code to make it work. They're honestly really simple. If you come up with a good one, feel free to send a PR and I'll add it for everyone else to use!

If your check finds a problem, it should add it to the `health_problems` array. Your alert will probably want to reference the `health_problems` array to generate some sort of message about the problems that are occurring.

## Uninstalling
Just delete `/usr/bin/healthbot`, `/etc/healthbot`, and `/etc/cron.d/healthbot`. There might also be an empty file at `/tmp/healthbot_stamp`, which you can delete.

## Credits
Inspired by [stephenlang/system-health-check](https://github.com/stephenlang/system-health-check) and [nozel-org/serverbot](https://github.com/nozel-org/serverbot). Thanks!!
