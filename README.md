# Ghostty terminal setup

Replicates a Ghostty + Oh My Zsh + Starship setup (Monokai Classic, syntax highlighting, autosuggestions, fzf, eza aliases, `updateall`).

## What you get

| Piece | Details |
|--------|---------|
| **Ghostty** | Theme `Monokai Classic`, MesloLGS Nerd Font, subtle Team Rocket background |
| **Oh My Zsh** | Plugins: git, docker, pyautoenv, autosuggestions, completions, history-substring-search, fzf-history-search, you-should-use, zsh-bat, syntax-highlighting |
| **Starship** | Catppuccin Mocha palette powerline prompt |
| **CLI tools** | fzf, eza, bat, fd, ripgrep, zoxide, mas |
| **Aliases** | `ls` / `lt` / `lta` / `lt3` / `ltd` / … via eza |
| **Helpers** | `updateall` (brew + macOS + mas + pip + npm) |

Green/red command coloring comes from **zsh-syntax-highlighting**. Grey command suggestions come from **zsh-autosuggestions**.

## Requirements

- macOS
- Network access (Homebrew, Oh My Zsh, plugins)
- Admin rights for Homebrew / shell change if needed

## Usage on a new Mac

```bash
# Copy or clone this folder, then:
cd ~/Plantillas/ghostty-terminal-setup
chmod +x install.sh
./install.sh
```

Existing `~/.zshrc`, Starship, and Ghostty configs are backed up under `~/.dotfiles-backup-YYYYMMDD-HHMMSS/` before overwrite.

Reopen Ghostty when the script finishes.

## Layout

```
ghostty-terminal-setup/
├── install.sh              # one-shot bootstrap
├── configs/
│   ├── zshrc               → ~/.zshrc
│   ├── starship.toml       → ~/.config/starship.toml
│   └── ghostty/config      → ~/.config/ghostty/config
└── assets/
    └── team-rocket.png     → ~/Pictures/fondos/team-rocket.png
```

## After install

- `lt` — directory tree
- `updateall` — update brew / system / App Store / pip / npm
- `Ctrl+R` — fuzzy history (fzf)

## Notes

- Installer is **macOS-only** (Homebrew + Ghostty cask).
- `node@22` PATH entry in `.zshrc` is optional; harmless if that formula is missing.
- forgit is cloned but left commented in `.zshrc` (same as the reference machine).
- To refresh configs later after editing this repo, re-run `./install.sh` (packages/plugins are idempotent; configs are re-copied with a new backup).
