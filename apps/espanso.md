# Espanso (Text-Expansion Trigger)

**Espanso** allows you to type a keyword anywhere (e.g., `:devlogin` or `!bg-dev`) and automatically replace it.

1. **Install Espanso for Wayland**:
```bash
sudo dnf copr enable eclipseo/espanso
sudo dnf install espanso-wayland

```


2. **Register the systemd service and start it**:
```bash
espanso service register
espanso start

```


3. **Configure the snippet**:
Open `~/.config/espanso/match/base.yml` and add:
```yaml
matches:
  - trigger: "!bg-dev"
    replace: "dev-user@example.com\tSuperSecretPass123!\n"
    backend: inject

```


*Note: Using `\t` inserts a tab character and `\n` triggers Enter. In many web forms, `backend: inject` will interpret `\t` as navigating to the next input field.*
