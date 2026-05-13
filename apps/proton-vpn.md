# Proton VPN MTU Fix

There is an issue with the MTU on the Proton VPN servers. The MTU is too high, and it's causing issues with the connection. Its specifically the o2 server that is affected.

To make the MTU fix permanent so it survives reboots and reconnections, you need to apply it directly to the NetworkManager profile for that specific ProtonVPN server.


#### Option 2: NetworkManager Dispatcher (The Pro Way)

You can create a small script that detects when a VPN comes up and automatically drops the MTU. This is the most "Senior Dev" approach because it works for *any* server you connect to.

1. Create the script:
```bash
sudo nano /etc/NetworkManager/dispatcher.d/99-vpn-mtu

```


2. Paste this in:

```bash
   #!/bin/bash
   Interface=$1
   Status=$2

   if [ "$Interface" == "proton0" ] && [ "$Status" == "up" ]; then
       /usr/sbin/ip link set dev proton0 mtu 1280
   fi

```

3. Make it executable:
```bash
sudo chmod +x /etc/NetworkManager/dispatcher.d/99-vpn-mtu

```



### Why this matters for your setup

On a 4090/i9 build, you're likely pushing high-resolution content or large git pulls. When the MTU is too high (1420), o2's hardware tries to "fragment" the packets. Most modern security headers in WireGuard don't like being split up, so the router just discards them. By forcing **1280**, you ensure the packets are small enough to slide through o2's network without being touched.

Does the `nmcli` command resolve the timeout issue on that specific server for now?

```