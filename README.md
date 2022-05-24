**Current version v1.2.15**

# Don't Starve Together cmd launcher.

* No powershell used.
* No WSH (wscript/cscript) used.
* No wmi used.
* Windows 7 unsupported (some patch needed).
* Windows 10 supported (build 17063 and above).
* Guided first run.
* Non-latin characters, spaces and special symbols allowed in pathnames.
* Changable master and/or caves autostart.
* World backup with rotation (last 5 "pre-run" backups are kept).
* Version check (can be disabled).
* Multilanguage (auto generated using sed with predefined strings substitutions).
* *Optional:* Lua interpreter can be used for auto-generate dedicated_server_mods_setup.lua (based on modoverrides.lua).

## Install
Clone. Or download and unzip (don't forget to unzip before run).

https://github.com/trng/dstcmdlauncher/archive/refs/heads/main.zip

Run `StartDSTwithParams.cmd`

First run - guided. All parameters except *Cluster name* have default values.

Configuration file will be created in the current folder.

Put your token to cluster_token.txt inside cluster folder (you will be prompted to do this during first run).

(Generate token here: https://accounts.klei.com/login?goto=https://accounts.klei.com/account/game/servers?game=DontStarveTogether)



## Advanced usage
Create empty folder. Create shortcut to `StartDSTwithParams.cmd` within this folder. Edit shortcut and set working dir to this folder. Run `StartDSTwithParams.cmd` via shortcut. All necessary files/folders will be created within this folder.

Also - you can specify config file name in the command line via shortcut (for example - on desktop).

With different configs/folders you can run multiple dst servers on one computer. Only one copy of `StartDSTwithParams.cmd` and templates folders needed.
