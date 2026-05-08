##  /usr/lib/systemd/system/logid.service

```service
[Unit]
Description=Logitech Configuration Daemon
StartLimitIntervalSec=0
After=multi-user.target
Wants=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/logid
User=root
Restart=on-failure
RestartSec=3
ExecStartPre=/bin/sleep 2

[Install]
WantedBy=graphical.target
```