## KDE Plasma 6 — Quick Launcher & Workflow Notes

### 1. Emoji Selection

- **Tiling Fix (Kröhnkite):** To prevent Kröhnkite from tiling the selector, add its class to the float list:
  - System Settings → Kröhnkite → Rules → **Float Windows (By Class)**:
  `org.kde.plasma.emojier,plasma-emojier,org.kde.kcharselect`
  - *Note:* Restart the Kröhnkite KWin script after modifying rules to apply changes.
  - *Manual Toggle:* `Meta` + `Shift` + `F` (toggles floating status on active window).

---



### 2. Translation in KRunner

- **Extension:** Use `krunner-translator` (C++/Qt6 rewritten for Plasma 6).
- **Dependencies & Setup:**
  ```bash
  # 1. Install translate-shell
  sudo dnf install translate-shell

  # 2. Build / Install Extension
  git clone [https://github.com/naraesk/krunner-translator.git](https://github.com/naraesk/krunner-translator.git)
  cd krunner-translator
  ./install.sh

  # 3. Restart KRunner
  krunner --replace &
  ```

* **Usage Examples:**
* `en-de house` → Translates "house" into German.
* `de soccer` → Translates "soccer" into German automatically.
* *Clicking the result copies it directly to the clipboard.*


