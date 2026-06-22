##  /usr/lib/systemd/system/logid.service

```service
[Unit]
Description=Logitech Configuration Daemon
StartLimitIntervalSec=0
After=graphical.target
Wants=graphical.target

[Service]
Type=simple
ExecStart=/usr/local/bin/logid
User=root
Restart=always
RestartSec=3s
ExecStartPre=/bin/sleep 2

[Install]
WantedBy=graphical.target
```