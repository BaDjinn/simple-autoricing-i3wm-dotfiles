#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# install-debian.sh - LMDE 6 / Debian 12 installer
# - Installa dipendenze via apt (i3, rofi, alacritty, picom, dunst, feh...)
# - Installa m3wal via pipx (alternativa ad AUR)
# - Installa Oh My Posh (installer ufficiale) + tema Tokyo per Bash
# - Installa CodeNewRoman Nerd Font (consigliata variante Mono) + fc-cache
# - Backup e copia dotfiles dal repo nella home
# ============================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
POSH_THEMES_DIR="$HOME/.poshthemes"
FONT_DIR="$HOME/.local/share/fonts"
DOWNLOADS_DIR="$HOME/Downloads"
NF_TMP_DIR="$DOWNLOADS_DIR/nerdfonts"
CODENEWROMAN_ZIP="$NF_TMP_DIR/CodeNewRoman.zip"

# ---------- Helpers ----------
log()  { printf "\n\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\n\033[1;31m[ERR ]\033[0m %s\n" "$*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Comando mancante: $1"; exit 1; }
}

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

# ---------- Distro check ----------
log "Controllo distribuzione (LMDE/Debian-based)..."
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  # LMDE 6 è basata su Debian 12 (Bookworm)
  if [[ "${ID_LIKE:-}" != *"debian"* && "${ID:-}" != "debian" && "${NAME:-}" != *"LMDE"* ]]; then
    warn "Questa script è pensata per Debian/LMDE. Continuo comunque, ma potresti dover adattare i pacchetti."
  fi
else
  warn "Impossibile leggere /etc/os-release. Continuo comunque."
fi

# ---------- APT packages ----------
log "Aggiorno apt e installo pacchetti base..."
sudo apt update

# Pacchetti "core" coerenti con lo stack del repo (i3/rofi/alacritty/picom/dunst/feh) + prerequisiti
# i3-wm e rofi sono disponibili via apt su Debian-based. (Debian 12 / LMDE 6)
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

# ---------- pipx path ----------
log "Assicuro pipx e PATH (per ~/.local/bin)..."
python3 -m pipx ensurepath >/dev/null 2>&1 || true

# ---------- m3wal via pipx ----------
log "Installo/aggiorno m3wal via pipx (alternativa all'AUR)..."
if command -v m3wal >/dev/null 2>&1; then
  pipx upgrade m3wal || true
else
  pipx install m3wal
fi

# ---------- Oh My Posh ----------
log "Installo Oh My Posh (script ufficiale per Linux)..."
# Lo script ufficiale installa in ~/bin oppure ~/.local/bin in base a cosa esiste
curl -s https://ohmyposh.dev/install.sh | bash -s

# ---------- Oh My Posh Theme: Tokyo ----------
log "Configuro Oh My Posh: scarico tema Tokyo localmente..."
mkdir -p "$POSH_THEMES_DIR"
curl -L \
  https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/tokyo.omp.json \
  -o "$POSH_THEMES_DIR/tokyo.omp.json"

# ---------- Bash init (Oh My Posh) ----------
log "Aggiorno ~/.bashrc per inizializzare Oh My Posh (tema Tokyo)..."
BASHRC_SNIPPET='
# --- Oh My Posh (Tokyo) ---
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init bash --config ~/.poshthemes/tokyo.omp.json)"
fi
'
append_if_missing "$HOME/.bashrc" "# --- Oh My Posh (Tokyo) ---" "$BASHRC_SNIPPET"

# ---------- Nerd Font: CodeNewRoman ----------
log "Installo CodeNewRoman Nerd Font (user-local) e aggiorno cache font..."
mkdir -p "$FONT_DIR" "$NF_TMP_DIR"

# Download zip (mirror Nerd Fonts)
curl -L -o "$CODENEWROMAN_ZIP" \
  "https://sourceforge.net/projects/nerd-fonts.mirror/files/v3.2.0/CodeNewRoman.zip/download"

# Estrai e copia font
TMP_EXTRACT_DIR="$(mktemp -d)"
unzip -o "$CODENEWROMAN_ZIP" -d "$TMP_EXTRACT_DIR" >/dev/null

# Copia TTF/OTF in ~/.local/share/fonts
find "$TMP_EXTRACT_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec cp -f {} "$FONT_DIR/" \;

# Aggiorna cache font
fc-cache -fv >/dev/null

rm -rf "$TMP_EXTRACT_DIR"

# ---------- Backup dotfiles ----------
log "Backup delle configurazioni esistenti in: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Backup principali
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

# ---------- Copy dotfiles from repo ----------
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

# Eseguibili in ~/.local/bin
if [ -d "$HOME/.local/bin" ]; then
  chmod -R u+x "$HOME/.local/bin" 2>/dev/null || true
fi

# ---------- Optional: Alacritty font setting ----------
# Provo a impostare CodeNewRoman Nerd Font Mono se esiste un config alacritty.yml o alacritty.toml.
log "Provo a impostare CodeNewRoman Nerd Font Mono in Alacritty (se config presente)..."
ALACRITTY_YML="$HOME/.config/alacritty/alacritty.yml"
ALACRITTY_TOML="$HOME/.config/alacritty/alacritty.toml"

if [ -f "$ALACRITTY_YML" ]; then
  # Inserisce un blocco font se non c'è già un 'font:' top-level.
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
  # Inserisce un blocco font se non c'è già [font]
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
  warn "Config Alacritty non trovato (alacritty.yml/toml). Se lo crei, imposta family: CodeNewRoman Nerd Font Mono."
fi

# ---------- Eww note ----------
warn "Nota: il repo usa Eww per barra/widgets. Su Debian/LMDE l'installazione può richiedere pacchetto esterno o build."
warn "Se dopo il login in i3 la barra non parte, il primo controllo è: 'command -v eww' e poi installazione Eww."

# ---------- Done ----------
log "Completato."
log "Cosa fare ora:"
echo "  1) Apri un nuovo terminale oppure esegui:  source ~/.bashrc"
echo "  2) Logout -> seleziona sessione i3 -> Login (come flusso tipico del progetto i3)."
echo "  3) Verifica Oh My Posh:  oh-my-posh version"
echo "  4) Verifica font:        fc-match 'CodeNewRoman Nerd Font Mono'"
echo
log "Tema Oh My Posh: Tokyo (file locale: ~/.poshthemes/tokyo.omp.json)"
