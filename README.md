# Overview

This script measures the battery level of Apple Magic Mouse and Magic Keyboard and sends it to Zabbix Server. You can then use the Zabbix web interface to check how they change over time and get notified before they run out completely.

# Requirements

- macOS
- Apple Magic Mouse and Magic Keyboard
- Zabbix server

# Installation

## Download the source files

```
git clone https://github.com/daisuke-f/my-magic-mouse-battery-monitor.git
```

## Prepare Zabbix server

If you don't have a Zabbix server, *Docker Compose* will be the fastest way to have it.

```
git clone https://github.com/zabbix/zabbix-docker.git

docker compose --file ./compose.yaml up --detach
```

## Configure Zabbix server

After getting your Zabbix server up, it is required to add a _host_ to it so that it can receive monitoring data.

First, log in to the Zabbix web interface. If you are using Docker Compose version of Zabbix server, the URL is http://localhost/ and username/password are shown [here](https://www.zabbix.com/documentation/current/en/manual/quickstart/login).

Next, import `zbx_export_hosts.xml` in the _Host_ section under the _Data collection_ (or _Configuration_ in the older version) to add a new _host_ entry named "mymac".

## Configure script file

You also have to configure for the script file if you are using own (not Docker Compose version) Zabbix server. The following shell variables in the script should be changed to point to your Zabbix server.

```
SERVER=127.0.0.1
PORT=10051
```

## Test script file

Let's run the script manually to check if everything goes on correctly.

```
./MyBatteryMonitor.sh 
```

You will get output like this if there is no trouble. "Response:" indicates that the Zabbix server successfully receives 2 monitoring item values (mouse.battery and keyboard.battery) sent from the script.

```
[2024-08-13 17:26:02] Start sending
[2024-08-13 17:26:02] Request: {"request":"sender data","data":[{"host":"mymac","key":"mouse.battery","value":"98"},{"host":"mymac","key":"keyboard.battery","value":"45"}]}
[2024-08-13 17:26:02] Response: ZBXDZ{"response":"success","info":"processed: 2; failed: 0; total: 2; seconds spent: 0.000897"}
```

You can also see these values in the _Latest data_ section of Zabbix web interface.

## Create launchd service

The script should be executed automatically not manually. So, we will use _launchd_ daemon on macOS to run it as a local service.

The `MyBatteryMonitor.plist` file contains the definition of the service. Note that you must edit this file to replace `/path/to/` into the actual installation directory.

After editing the file, execute this command to register the service.

```
launchctl bootstrap gui/$UID ./MyBatteryMonitor.plist
```

The service status will be shown by this command:

```
launchctl print gui/$UID/asia.sarapan.MyBatteryMonitor
```

The script is scheduled to be executed once an hour. The log records can be seen by this command:

```
log show --predicate 'subsystem CONTAINS "asia.sarapan.MyBatteryMonitor"' --last 6h
```

# Uninstallation

## Remove launchd service

```
launchctl bootout gui/$UID/asia.sarapan.MyBatteryMonitor
```

## Remove Zabbix server

```
docker compose --file ./compose.yaml down
```