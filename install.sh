#!/usr/bin/env bash
# Bootstrap Ghostty + Oh My Zsh + Starship to match the reference machine.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
FAILED_CASKS=()

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { printf "${CYAN}==>${NC} %s\n" "$*"; }
ok()    { printf "${GREEN}✓${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}!${NC} %s\n" "$*"; }
fail()  { printf "${RED}✗${NC} %s\n" "$*"; exit 1; }

backup_file() {
  local src="$1"
  if [[ -e "$src" || -L "$src" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "${src#"$HOME"/}")"
    cp -a "$src" "$BACKUP_DIR/${src#"$HOME"/}"
    ok "Backed up $src"
  fi
}

require_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || fail "This installer targets macOS (Homebrew + Ghostty)."
}

install_homebrew() {
  if command -v brew &>/dev/null; then
    ok "Homebrew already installed"
    return
  fi
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  ok "Homebrew installed"
}

ensure_brew_in_path() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  command -v brew &>/dev/null || fail "brew not found after install"
}

retry() {
  local attempts="$1"; shift
  local n=1
  until "$@"; do
    if (( n >= attempts )); then
      return 1
    fi
    warn "Attempt $n/$attempts failed: $* (retrying in $((n * 5))s)"
    sleep $((n * 5))
    ((n++))
  done
}

install_cask() {
  local cask="$1"
  if brew list --cask "$cask" &>/dev/null; then
    ok "Cask already installed: $cask"
    return 0
  fi
  # --adopt takes over an app already present in /Applications instead of erroring
  if retry 3 brew install --cask --adopt "$cask"; then
    ok "Installed cask: $cask"
    return 0
  fi
  warn "Could not install cask: $cask (continuing)"
  FAILED_CASKS+=("$cask")
  return 0
}

unmark_failed_cask() {
  local target="$1" kept=() item
  for item in "${FAILED_CASKS[@]-}"; do
    if [[ -n "$item" && "$item" != "$target" ]]; then
      kept+=("$item")
    fi
  done
  if (( ${#kept[@]} )); then
    FAILED_CASKS=("${kept[@]}")
  else
    FAILED_CASKS=()
  fi
}

install_meslo_font_manually() {
  local font_dir="${HOME}/Library/Fonts"
  if compgen -G "${font_dir}/MesloLG*Nerd*" >/dev/null || compgen -G "/Library/Fonts/MesloLG*Nerd*" >/dev/null; then
    ok "MesloLG Nerd Font already present"
    unmark_failed_cask font-meslo-lg-nerd-font
    return 0
  fi

  info "Falling back to direct download of MesloLG Nerd Font..."
  local tmp url
  tmp="$(mktemp -d)"
  url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.tar.xz"
  if retry 3 curl -fsSL --retry 3 --retry-all-errors -o "${tmp}/Meslo.tar.xz" "$url"; then
    mkdir -p "$font_dir"
    if tar -xJf "${tmp}/Meslo.tar.xz" -C "$tmp" && find "$tmp" -name '*.ttf' -exec cp {} "$font_dir" \;; then
      ok "MesloLG Nerd Font installed to $font_dir"
      unmark_failed_cask font-meslo-lg-nerd-font
      rm -rf "$tmp"
      return 0
    fi
  fi
  rm -rf "$tmp"
  warn "Font download failed. Install it later with: brew install --cask font-meslo-lg-nerd-font"
}

install_packages() {
  info "Installing Homebrew packages..."
  local formulae=(starship fzf eza bat fd ripgrep mas zoxide git lazygit)
  local casks=(ghostty font-meslo-lg-nerd-font)

  brew update || warn "brew update failed (continuing with cached formulae)"
  brew install "${formulae[@]}"

  local cask
  for cask in "${casks[@]}"; do
    install_cask "$cask"
  done

  if [[ " ${FAILED_CASKS[*]-} " == *" font-meslo-lg-nerd-font "* ]]; then
    install_meslo_font_manually
  fi
  ok "Packages installed"

  info "Installing fzf key bindings..."
  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish || true
  ok "fzf configured"
}

install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "Oh My Zsh already installed"
    return
  fi
  info "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  ok "Oh My Zsh installed"
}

clone_plugin() {
  local name="$1"
  local url="$2"
  local dest="${ZSH_CUSTOM}/plugins/${name}"
  if [[ -d "$dest/.git" ]]; then
    info "Updating plugin: $name"
    git -C "$dest" pull --ff-only || warn "Could not update $name"
  elif [[ -d "$dest" ]]; then
    warn "Plugin dir exists but is not a git repo: $dest (skipping)"
  else
    info "Cloning plugin: $name"
    git clone --depth=1 "$url" "$dest"
  fi
}

install_plugins() {
  mkdir -p "${ZSH_CUSTOM}/plugins"
  clone_plugin zsh-autosuggestions           https://github.com/zsh-users/zsh-autosuggestions
  clone_plugin zsh-completions               https://github.com/zsh-users/zsh-completions
  clone_plugin zsh-history-substring-search  https://github.com/zsh-users/zsh-history-substring-search
  clone_plugin zsh-fzf-history-search        https://github.com/joshskidmore/zsh-fzf-history-search
  clone_plugin zsh-you-should-use            https://github.com/MichaelAquilina/zsh-you-should-use
  clone_plugin zsh-bat                       https://github.com/fdellwing/zsh-bat.git
  clone_plugin zsh-syntax-highlighting       https://github.com/zsh-users/zsh-syntax-highlighting
  clone_plugin pyautoenv                     https://github.com/hsaunders1904/pyautoenv.git
  # forgit is optional / commented in zshrc; clone for convenience
  clone_plugin forgit                        https://github.com/wfxr/forgit

  # OMZ plugin list uses "you-should-use"
  local ysu_link="${ZSH_CUSTOM}/plugins/you-should-use"
  if [[ ! -e "$ysu_link" ]]; then
    ln -s zsh-you-should-use "$ysu_link"
    ok "Linked you-should-use -> zsh-you-should-use"
  fi
}

install_background() {
  local src="${REPO_DIR}/assets/team-rocket.png"
  local dest_dir="${HOME}/Pictures/fondos"
  local dest="${dest_dir}/team-rocket.png"
  mkdir -p "$dest_dir"
  if [[ -f "$src" ]]; then
    cp -n "$src" "$dest" 2>/dev/null || cp "$src" "$dest"
    ok "Background image at $dest"
  else
    warn "No background asset found; Ghostty will still work without it"
  fi
}

install_configs() {
  info "Installing config files (backups go to $BACKUP_DIR)..."

  backup_file "$HOME/.zshrc"
  backup_file "$HOME/.config/starship.toml"
  backup_file "$HOME/.config/ghostty/config"

  mkdir -p "$HOME/.config/ghostty"

  cp "${REPO_DIR}/configs/zshrc" "$HOME/.zshrc"
  cp "${REPO_DIR}/configs/starship.toml" "$HOME/.config/starship.toml"
  cp "${REPO_DIR}/configs/ghostty/config" "$HOME/.config/ghostty/config"

  # Ensure Homebrew PATH snippet for Apple Silicon / Intel
  if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
    {
      echo ''
      echo '# Homebrew'
      if [[ -x /opt/homebrew/bin/brew ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
      elif [[ -x /usr/local/bin/brew ]]; then
        echo 'eval "$(/usr/local/bin/brew shellenv)"'
      fi
    } >> "$HOME/.zprofile"
    ok "Added brew shellenv to ~/.zprofile"
  fi

  ok "Configs installed"
}

set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ "$SHELL" == "$zsh_path" ]]; then
    ok "Default shell already zsh"
    return
  fi
  if ! grep -q "^${zsh_path}$" /etc/shells 2>/dev/null; then
    warn "Adding $zsh_path to /etc/shells (may ask for password)"
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi
  info "Setting default shell to zsh..."
  chsh -s "$zsh_path" || warn "Could not change shell automatically; run: chsh -s $zsh_path"
}

print_summary() {
  if (( ${#FAILED_CASKS[@]} )) && [[ -n "${FAILED_CASKS[0]-}" ]]; then
    warn "These casks could not be installed: ${FAILED_CASKS[*]}"
    warn "Retry later with: brew install --cask --adopt ${FAILED_CASKS[*]}"
  fi

  cat <<EOF

${GREEN}═══════════════════════════════════════════════════════════${NC}
  Terminal setup complete.
${GREEN}═══════════════════════════════════════════════════════════${NC}

  Installed / configured:
    • Ghostty (theme: Monokai Classic, MesloLGS Nerd Font)
    • Oh My Zsh + plugins (syntax highlighting, autosuggestions,
      fzf history, you-should-use, bat, pyautoenv, …)
    • Starship prompt
    • eza aliases (ls, lt, lta, lt3, ltd, …)
    • updateall helper
    • fzf, bat, fd, ripgrep, zoxide, mas, lazygit

  Next steps:
    1. Reload Ghostty config with Cmd+Shift+, (or quit and reopen it).
       Without a reload the theme, font and background image stay as-is.
    2. If fonts look wrong: Ghostty → Settings, confirm MesloLGS Nerd Font
    3. Optional backups are in: ${BACKUP_DIR}

  Useful commands after restart:
    lt          tree view (eza)
    updateall   brew + macOS + mas + pip + npm updates
    Ctrl+R      fzf history search

EOF
}

main() {
  info "Ghostty terminal bootstrap from: $REPO_DIR"
  require_macos
  install_homebrew
  ensure_brew_in_path
  install_packages
  install_oh_my_zsh
  install_plugins
  install_background
  install_configs
  set_default_shell
  print_summary
}

main "$@"
