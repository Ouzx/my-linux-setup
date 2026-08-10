**Btrfs Snapshot Exclusion Cheat Sheet**

To exclude any directory from Btrfs snapshots (like Snapper), convert it into a nested subvolume. Snapshots do not cross subvolume boundaries.

```bash
# Function to convert existing folder into a Btrfs nested subvolume (zsh-safe)
btrfs_exclude() {
  local target="$1"
  [[ -d "$target" ]] || return 1

  mv "$target" "${target}_old" && \
  btrfs subvolume create "$target" && \
  mv "${target}_old"/*(D) "$target"/ 2>/dev/null && \
  rmdir "${target}_old"
}

# Example usage for Games & Videos:
btrfs_exclude ~/Games
btrfs_exclude ~/Videos

```

**Key Notes**

* `*(D)` is required in `zsh` to capture hidden dotfiles/folders safely without syntax errors.
* After running, verify in Btrfs Assistant under the **Subvolumes** tab that the new path appears as its own subvolume entry.