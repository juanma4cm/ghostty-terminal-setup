# Ghostty terminal setup

One-shot macOS installer that recreates a Ghostty + Oh My Zsh + Starship terminal: Monokai Classic, syntax highlighting, autosuggestions, fzf, eza aliases, and helpers like `updateall`.

**License:** [MIT](LICENSE) — free to use, copy, and adapt. Third-party tools and Oh My Zsh plugins keep their own licenses.

## What you get

| Piece | Details |
|--------|---------|
| **Ghostty** | Theme `Monokai Classic`, MesloLGS Nerd Font, subtle free-license letter background |
| **Oh My Zsh** | Plugins: git, docker, pyautoenv, autosuggestions, completions, history-substring-search, fzf-history-search, you-should-use, zsh-bat, syntax-highlighting |
| **Starship** | Catppuccin Mocha palette powerline prompt |
| **CLI tools** | fzf, eza, bat, fd, ripgrep, zoxide, mas, lazygit |
| **Aliases** | `ls` / `lt` / `lta` / `lt3` / `ltd` / … via eza |
| **Helpers** | `updateall` (brew + macOS + mas + pip + npm) |

Green/red command coloring comes from **zsh-syntax-highlighting**. Grey command suggestions come from **zsh-autosuggestions**.

## Requirements

- macOS
- Network access (Homebrew, Oh My Zsh, plugins)
- Admin rights for Homebrew / shell change if needed

## Usage on a new Mac

```bash
git clone <your-repo-url> ~/Plantillas/ghostty-terminal-setup
cd ~/Plantillas/ghostty-terminal-setup
chmod +x install.sh
./install.sh
```

Existing `~/.zshrc`, Starship, and Ghostty configs are backed up under `~/.dotfiles-backup-YYYYMMDD-HHMMSS/` before overwrite.

When the script finishes, reload the Ghostty config with `Cmd+Shift+,` (or quit and reopen Ghostty). Until you do, theme, font and background keep their previous values.

## Layout

```
ghostty-terminal-setup/
├── install.sh              # one-shot bootstrap
├── LICENSE                 # MIT
├── configs/
│   ├── zshrc               → ~/.zshrc
│   ├── starship.toml       → ~/.config/starship.toml
│   └── ghostty/config      → ~/.config/ghostty/config
└── assets/
    └── c-letter.png        → ~/Pictures/fondos/c-letter.png
```

## After install

- `lt` — directory tree
- `updateall` — update brew / system / App Store / pip / npm
- `Ctrl+R` — fuzzy history (fzf)

## Background image

The default wallpaper is `assets/c-letter.png` — a free-license image included on purpose (safe to redistribute with this MIT project). The installer copies it to `~/Pictures/fondos/c-letter.png`, and Ghostty’s config points there with low opacity.

To use a different image:

1. Replace or add a PNG under `~/Pictures/fondos/` (or under `assets/` before running the installer).
2. Update `background-image` in `configs/ghostty/config` (and on the machine: `~/.config/ghostty/config`).
3. Reload Ghostty with `Cmd+Shift+,`.

Extra personal wallpapers under `assets/` stay gitignored so only the free default is published.

## Making this repo public

Safe to publish under MIT. Before you go public:

- Do **not** commit third-party logos or trademarked art (e.g. Pokémon / Team Rocket). This repo ships only the free-license `c-letter.png`.
- Scan configs for secrets, tokens, or private paths.
- Plugins are cloned at install time from their upstream repos; this project only documents them.

## Notes

- Installer is **macOS-only** (Homebrew + Ghostty cask).
- `node@22` PATH entry in `.zshrc` is optional; harmless if that formula is missing.
- forgit is cloned but left commented in `.zshrc` (same as the reference machine).
- To refresh configs later, re-run `./install.sh` (packages/plugins are idempotent; configs are re-copied with a new backup).
