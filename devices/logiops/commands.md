https://github.com/PixlOne/logiops

> sudo nano /etc/logid.cfg

> sudo systemctl restart logid

> sudo journalctl -u logid -f

## To find button ids;

They are not in order, random.

```sh
sudo systemctl stop logid
sudo logid -v debug
```