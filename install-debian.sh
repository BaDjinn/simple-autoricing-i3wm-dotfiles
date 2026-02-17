#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# install-debian.sh - LMDE 6 / Debian 12 installer
# - apt: i3, rofi, alacritty, picom, dunst, feh...
# - m3wal via pipx
# - Oh My Posh + tema Tokyo (Bash)
# - CodeNewRoman Nerd Font + fc-cache
# - Auto-install Eww (apt -> build X11)
# - Backup + copia dotfiles
# - Post-install check (OK/FAIL + suggerimenti)
# ============================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

POSH_THEMES_DIR="$HOME/.poshthemes"
POSH_TOKYO="$POSH_THEMES_DIR/tokyo.omp.json"

FONT_DIR="$HOME/.local/share/fonts"
DOWNLOADS_DIR="$HOME/Downloads"
NF_TMP_DIR="$DOWNLOADS_DIR/nerdfonts"
CODENEWROMAN_ZIP="$NF_TMP_DIR/CodeNewRoman.zip"

log()  { printf "\n\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\n\033[1;31m[ERR ]\033[0m %s\n" "$*"; }

append_if_missing() {
  local file="$1"
  local marker="$2"
  local content="$3"
  touch "$file"
  if ! grep -qF "$marker" "$file"; then
    printf "\n%s\n" "$content" >> "$file"
  fi
}

backup_path() {
  local p="$1"
  if [ -e "$p" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$p")"
    cp -a "$p" "$BACKUP_DIR/$p"
  fi
}

install_eww() {
  log "Eww: controllo presenza..."
  if command -v eww >/dev/null 2>&1; then
    log "Eww già installato: $(command -v eww)"
    return 0
  fi

  log "Eww: provo installazione via apt (se disponibile nei repo)..."
  if apt-cache show eww >/dev/null 2>&1; then
    sudo apt install -y eww || true
    if command -v eww >/dev/null 2>&1; then
      log "Eww installato via apt."
      return 0
    fi
  fi

  warn "Eww non disponibile via apt o installazione fallita: procedo con build da sorgente (X11)."

  log "Eww: installo dipendenze di build (GTK3/libs) e toolchain..."
  sudo apt update
  sudo apt install -y \
    build-essential \
    pkg-config \
    git \
    curl \
    libgtk-3-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libgdk-pixbuf-2.0-dev \
    libglib2.0-dev \
    libdbusmenu-gtk3-dev

  if ! command -v cargo >/dev/null 2>&1; then
    log "Eww: cargo non trovato, installo Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
  fi

  log "Eww: clono repo e compilo con feature X11..."
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  git clone --depth 1 https://github.com/elkowar/eww "$tmp_dir/eww"

  pushd "$tmp_dir/eww" >/dev/null
    # Build X11 come da doc ufficiale eww
    cargo build --release --no-default-features --features x11
    mkdir -p "$HOME/.local/bin"
    install -Dm755 target/release/eww "$HOME/.local/bin/eww"
  popd >/dev/null

  rm -rf "$tmp_dir"

  if command -v eww >/dev/null 2>&1; then
    log "Eww installato con successo in ~/.local/bin/eww"
    return 0
  fi

  err "Installazione Eww fallita. Controlla output e dipendenze."
  return 1
}

post_install_check() {
  log "POST-INSTALL CHECK (OK/FAIL) — componenti e configurazione"

  local fail=0

  check_cmd() {
    local name="$1"
    local hint="$2"
    if command -v "$name" >/dev/null 2>&1; then
      printf "  \033[1;32m[OK]\033[0m  %-12s -> %s\n" "$name" "$(command -v "$name")"
    else
      printf "  \033[1;31m[FAIL]\033[0m %-12s -> %s\n" "$name" "$hint"
      fail=1
    fi
  }

  echo
  log "Binari principali (stack progetto + tue richieste)"
  # Stack progetto: i3, eww, m3wal, picom, alacritty, rofi, dunst [1](https://github.com/elkowar/eww/issues/152)
  check_cmd i3        "sudo apt install i3-wm"
  check_cmd rofi      "sudo apt install rofi"
  check_cmd alacritty "sudo apt install alacritty"
  check_cmd picom     "sudo apt install picom"
  check_cmd dunst     "sudo apt install dunst"
  check_cmd feh       "sudo apt install feh"
  check_cmd m3wal     "pipx install m3wal  # (alternativa AUR)"
  check_cmd eww       "riesegui lo script (build X11) oppure installa manualmente"
  check_cmd oh-my-posh "curl -s https://ohmyposh.dev/install.sh | bash -s"

  echo
  log "Oh My Posh (Bash) + tema Tokyo"
  if [ -f "$POSH_TOKYO" ]; then
    printf "  \033[1;32m[OK]\033[0m  Tema Tokyo presente: %s\n" "$POSH_TOKYO"
  else
    printf "  \033[1;31m[FAIL]\033[0m Tema Tokyo mancante: %s\n" "$POSH_TOKYO"
    printf "        Fix: curl -L https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/tokyo.omp.json -o %s\n" "$POSH_TOKYO"
    fail=1
  fi

  if grep -qF 'oh-my-posh init bash --config ~/.poshthemes/tokyo.omp.json' "$HOME/.bashrc" 2>/dev/null; then
    printf "  \033[1;32m[OK]\033[0m  ~/.bashrc inizializza Oh My Posh (Tokyo)\n"
  else
    printf "  \033[1;31m[FAIL]\033[0m ~/.bashrc non contiene init Oh My Posh Tokyo\n"
    printf "        Fix: aggiungi in ~/.bashrc:\n"
    printf "        eval \"\$(oh-my-posh init bash --config ~/.poshthemes/tokyo.omp.json)\"\n"
    fail=1
  fi

  echo
  log "Font: CodeNewRoman Nerd Font"
  if command -v fc-match >/dev/null 2>&1; then
    local match
    match="$(fc-match "CodeNewRoman Nerd Font Mono" 2>/dev/null || true)"
    if [[ -n "$match" ]]; then
      printf "  \033[1;32m[OK]\033[0m  fc-match 'CodeNewRoman Nerd Font Mono' -> %s\n" "$match"
    else
      printf "  \033[1;31m[FAIL]\033[0m fc-match non trova 'CodeNewRoman Nerd Font Mono'\n"
      printf "        Fix: verifica i font disponibili: fc-list | grep -i CodeNewRoman\n"
      printf "        Poi imposta il family corretto in Alacritty.\n"
      fail=1
    fi
  else
    printf "  \033[1;31m[FAIL]\033[0m fc-match non disponibile (manca fontconfig)\n"
    printf "        Fix: sudo apt install fontconfig\n"
    fail=1
  fi

  echo
  log "Config Eww / i3 (file attesi)"
  if [ -d "$HOME/.config/eww" ]; then
    printf "  \033[1;32m[OK]\033[0m  ~/.config/eww presente\n"
  else
    printf "  \033[1;33m[WARN]\033[0m ~/.config/eww non presente (ok se non hai ancora copiato i dotfiles Eww)\n"
    printf "        Se il repo include Eww config, controlla che .config/eww sia stata copiata.\n"
  fi

  if [ -d "$HOME/.config/i3" ]; then
    printf "  \033[1;32m[OK]\033[0m  ~/.config/i3 presente\n"
  else
    printf "  \033[1;33m[WARN]\033[0m ~/.config/i3 non presente\n"
  fi

  echo
  log "Suggerimenti rapidi"
  printf "  - Ricarica bash:  source ~/.bashrc  (o apri un nuovo terminale)\n"
  printf "  - Avvia eww (se config presente):  eww daemon &  poi: eww open <nome_widget>\n"
  printf "  - Su i3: logout -> seleziona sessione i3 -> login\n"

  echo
  if [ "$fail" -eq 0 ]; then
    log "POST-INSTALL CHECK: \033[1;32mTUTTO OK\033[0m ✅"
  else
    warn "POST-INSTALL CHECK: \033[1;31mCI SONO FAIL\033[0m ❌ (vedi sopra per i fix)"
  fi
}

# --------- Distro check (soft) ----------
log "Controllo distribuzione (Debian/LMDE)..."
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${ID_LIKE:-}" != *"debian"* && "${ID:-}" != "debian" && "${NAME:-}" != *"LMDE"* ]]; then
    warn "Script pensato per Debian/LMDE: potresti dover adattare i pacchetti."
  fi
else
  warn "Impossibile leggere /etc/os-release. Continuo comunque."
fi

# --------- Pacchetti base ----------
log "Aggiorno apt e installo pacchetti base..."
sudo apt update

APT_PKGS=(
  i3-wm
  rofi
  alacritty
  picom
  dunst
  feh
  x11-xserver-utils
  xrandr
  xset
  git
  curl
  unzip
  ca-certificates
  python3
  python3-venv
  pipx
  fontconfig
  jq
)

sudo apt install -y "${APT_PKGS[@]}"

# --------- pipx path ----------
log "Assicuro pipx e PATH (per ~/.local/bin)..."
python3 -m pipx ensurepath >/dev/null 2>&1 || true

# --------- m3wal via pipx ----------
log "Installo/aggiorno m3wal via pipx..."
if command -v m3wal >/dev/null 2>&1; then
  pipx upgrade m3wal || true
else
  pipx install m3wal
fi

# --------- Oh My Posh + Tokyo ----------
log "Installo Oh My Posh (script ufficiale per Linux)..."
curl -s https://ohmyposh.dev/install.sh | bash -s

log "Oh My Posh: scarico tema Tokyo localmente..."
mkdir -p "$POSH_THEMES_DIR"
curl -L \
  https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/tokyo.omp.json \
  -o "$POSH_TOKYO"

log "Aggiorno ~/.bashrc per inizializzare Oh My Posh (Tokyo)..."
BASHRC_SNIPPET='
# --- Oh My Posh (Tokyo) ---
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init bash --config ~/.poshthemes/tokyo.omp.json)"
fi
'
append_if_missing "$HOME/.bashrc" "# --- Oh My Posh (Tokyo) ---" "$BASHRC_SNIPPET"

# --------- Nerd Font: CodeNewRoman ----------
log "Installo CodeNewRoman Nerd Font (user-local) e aggiorno cache font..."
mkdir -p "$FONT_DIR" "$NF_TMP_DIR"

curl -L -o "$CODENEWROMAN_ZIP" \
  "https://sourceforge.net/projects/nerd-fonts.mirror/files/v3.2.0/CodeNewRoman.zip/download"

TMP_EXTRACT_DIR="$(mktemp -d)"
unzip -o "$CODENEWROMAN_ZIP" -d "$TMP_EXTRACT_DIR" >/dev/null

find "$TMP_EXTRACT_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec cp -f {} "$FONT_DIR/" \;
fc-cache -fv >/dev/null

rm -rf "$TMP_EXTRACT_DIR"

# --------- Eww auto-install ----------
install_eww

# --------- Backup ----------
log "Backup delle configurazioni esistenti in: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

backup_path "$HOME/.config/i3"
backup_path "$HOME/.config/eww"
backup_path "$HOME/.config/rofi"
backup_path "$HOME/.config/picom"
backup_path "$HOME/.config/dunst"
backup_path "$HOME/.config/alacritty"
backup_path "$HOME/.config/m3-colors"
backup_path "$HOME/.local/bin"
backup_path "$HOME/.Xresources"
backup_path "$HOME/.xprofile"
backup_path "$HOME/.bashrc"

# --------- Copia dotfiles dal repo ----------
log "Copio dotfiles dal repo nella home..."
mkdir -p "$HOME/.config" "$HOME/.local/bin"

if [ -d "$REPO_DIR/.config" ]; then
  cp -a "$REPO_DIR/.config/." "$HOME/.config/"
else
  warn "Cartella .config non trovata nel repo: salto copia di ~/.config."
fi

if [ -d "$REPO_DIR/.local" ]; then
  cp -a "$REPO_DIR/.local/." "$HOME/.local/"
else
  warn "Cartella .local non trovata nel repo: salto copia di ~/.local."
fi

[ -f "$REPO_DIR/.Xresources" ] && cp -a "$REPO_DIR/.Xresources" "$HOME/.Xresources"
[ -f "$REPO_DIR/.xprofile" ]   && cp -a "$REPO_DIR/.xprofile"   "$HOME/.xprofile"

if [ -d "$HOME/.local/bin" ]; then
  chmod -R u+x "$HOME/.local/bin" 2>/dev/null || true
fi

# --------- Set font in Alacritty se config presente ----------
log "Provo a impostare CodeNewRoman Nerd Font Mono in Alacritty (se config presente)..."
ALACRITTY_YML="$HOME/.config/alacritty/alacritty.yml"
ALACRITTY_TOML="$HOME/.config/alacritty/alacritty.toml"

if [ -f "$ALACRITTY_YML" ]; then
  if ! grep -qE '^[[:space:]]*font:' "$ALACRITTY_YML"; then
    cat >> "$ALACRITTY_YML" <<'EOF'

# --- Font (Nerd Font) ---
font:
  normal:
    family: "CodeNewRoman Nerd Font Mono"
    style: Regular
  bold:
    family: "CodeNewRoman Nerd Font Mono"
    style: Bold
  italic:
    family: "CodeNewRoman Nerd Font Mono"
    style: Italic
  size: 12
EOF
  fi
elif [ -f "$ALACRITTY_TOML" ]; then
  if ! grep -qE '^\[font\]' "$ALACRITTY_TOML"; then
    cat >> "$ALACRITTY_TOML" <<'EOF'

# --- Font (Nerd Font) ---
[font]
size = 12

[font.normal]
family = "CodeNewRoman Nerd Font Mono"
style = "Regular"

[font.bold]
family = "CodeNewRoman Nerd Font Mono"
style = "Bold"

[font.italic]
family = "CodeNewRoman Nerd Font Mono"
style = "Italic"
EOF
  fi
else
  warn "Config Alacritty non trovato (alacritty.yml/toml)."
fi

# --------- Post install check ----------
post_install_check

# --------- Done ----------
log "Completato."
log "Prossimi passi:"
echo "  1) Ricarica bash:  source ~/.bashrc  (o apri un nuovo terminale)"
echo "  2) Logout -> seleziona sessione i3 -> Login"
echo "  3) Verifica Oh My Posh:  oh-my-posh version"
echo "  4) Verifica Eww:         eww --version  (o: eww -V)"
echo "  5) Verifica font:        fc-match 'CodeNewRoman Nerd Font Mono'"
echo
log "Oh My Posh tema: Tokyo (file locale: ~/.poshthemes/tokyo.omp.json)"
``
